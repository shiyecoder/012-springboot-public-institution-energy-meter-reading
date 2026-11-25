<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">抄表记录</div>
        <div class="page-sub">共 {{ total }} 条 · 已锁定记录调整需走审批</div>
      </div>
    </div>
    <div class="filter-bar">
      <el-select v-model="q.period" placeholder="全部周期" clearable style="width: 180px" @change="reload">
        <el-option v-for="p in periods" :key="p" :label="p" :value="p" />
      </el-select>
      <el-select v-model="q.reviewStatus" placeholder="复核状态" clearable style="width: 180px" @change="reload">
        <el-option label="待复核" value="PENDING" /><el-option label="已通过" value="PASS" />
        <el-option label="已退回" value="REJECT" />
      </el-select>
      <el-input v-model="q.keyword" placeholder="记录编号" clearable style="width: 200px" @keyup.enter="reload" />
      <el-button type="primary" @click="reload">查询</el-button>
    </div>
    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="readingNo" label="记录编号" min-width="150" />
        <el-table-column prop="buildingName" label="建筑" min-width="160" />
        <el-table-column prop="meterCode" label="表计" min-width="130" />
        <el-table-column prop="period" label="周期" min-width="90" />
        <el-table-column prop="prevReading" label="上期" min-width="100" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.prevReading) }}</span></template>
        </el-table-column>
        <el-table-column prop="currReading" label="本期" min-width="110" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.currReading) }}</span></template>
        </el-table-column>
        <el-table-column prop="usageAmount" label="用量" min-width="100" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.usageAmount) }}</span></template>
        </el-table-column>
        <el-table-column label="偏差" min-width="90" align="right">
          <template #default="{ row }">
            <span class="num" :class="Math.abs(row.deviationRate) > 20 ? 'up' : ''">{{ row.deviationRate }}%</span>
          </template>
        </el-table-column>
        <el-table-column label="照片" min-width="80">
          <template #default="{ row }">
            <el-image :src="row.photoPath" :preview-src-list="[row.photoPath]" fit="cover"
                      style="width: 40px; height: 30px; border-radius: 3px" />
          </template>
        </el-table-column>
        <el-table-column label="状态" min-width="110">
          <template #default="{ row }">
            <el-tag :type="row.locked ? 'info' : (row.reviewStatus === 'PASS' ? 'success' : row.reviewStatus === 'REJECT' ? 'danger' : 'warning')" effect="light">
              {{ row.locked ? '已锁定' : (row.taskStatusLabel || row.reviewStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="readTime" label="抄表时间" min-width="160">
          <template #default="{ row }">{{ formatTime(row.readTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :disabled="row.locked"
                       @click="openReview(row)">复核</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
                       :page-size="q.size" :current-page="q.page" :page-sizes="[10, 20, 50]"
                       @current-change="(p) => { q.page = p; load() }"
                       @size-change="(s) => { q.size = s; q.page = 1; load() }" />
      </div>
    </div>

    <el-dialog v-model="visible" title="数据复核" width="520px">
      <el-descriptions :column="2" border size="small" style="margin-bottom: 14px">
        <el-descriptions-item label="记录编号">{{ current.readingNo }}</el-descriptions-item>
        <el-descriptions-item label="表计">{{ current.meterCode }}</el-descriptions-item>
        <el-descriptions-item label="本期用量">{{ num(current.usageAmount) }}</el-descriptions-item>
        <el-descriptions-item label="偏差">{{ current.deviationRate }}%</el-descriptions-item>
      </el-descriptions>
      <el-radio-group v-model="action">
        <el-radio-button label="PASS">确认通过</el-radio-button>
        <el-radio-button label="REJECT">退回重录</el-radio-button>
        <el-radio-button label="EXCEPTION">转异常</el-radio-button>
      </el-radio-group>
      <el-input v-model="note" type="textarea" :rows="3" style="margin-top: 12px"
                :placeholder="action === 'PASS' ? '可选填写复核意见' : '退回或转异常必须填写原因（不少于 5 个字）'" />
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="doReview">提交复核</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { readingApi } from '../api'
import { formatTime, num } from '../utils/format'

const rows = ref([])
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const current = ref({})
const action = ref('PASS')
const note = ref('')
const periods = ['2026-10', '2026-09', '2026-08', '2026-07', '2026-06', '2026-05']
const q = reactive({ page: 1, size: 10, period: '2026-10', reviewStatus: null, keyword: '' })

async function load() {
  loading.value = true
  try {
    const d = await readingApi.page({ ...q, keyword: q.keyword || undefined })
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}
function reload() { q.page = 1; load() }

function openReview(row) {
  current.value = row
  action.value = 'PASS'
  note.value = ''
  visible.value = true
}

async function doReview() {
  if (action.value !== 'PASS' && note.value.trim().length < 5) {
    ElMessage.warning('原因不少于 5 个字')
    return
  }
  await readingApi.review(current.value.id, { action: action.value, note: note.value })
  ElMessage.success('复核完成')
  visible.value = false
  load()
}

onMounted(load)
</script>

<style scoped>
.head { display: flex; justify-content: space-between; margin-bottom: 14px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
</style>

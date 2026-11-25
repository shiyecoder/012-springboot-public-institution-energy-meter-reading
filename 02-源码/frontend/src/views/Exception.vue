<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">异常复核中心</div>
        <div class="page-sub">共 {{ total }} 条异常 · 待处理 {{ openCount }} 条 · 处置原因必填且留痕</div>
      </div>
    </div>
    <div class="filter-bar">
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 180px" @change="reload">
        <el-option label="待处理" value="OPEN" /><el-option label="处理中" value="HANDLING" />
        <el-option label="已关闭" value="CLOSED" /><el-option label="已忽略" value="IGNORED" />
      </el-select>
      <el-select v-model="q.exceptionType" placeholder="全部类型" clearable style="width: 180px" @change="reload">
        <el-option label="突增" value="SURGE" /><el-option label="突降" value="DROP" />
        <el-option label="长期不变" value="FLAT" /><el-option label="表计损坏" value="DAMAGE" />
        <el-option label="级联异常" value="CASCADE" />
      </el-select>
    </div>
    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="exceptionNo" label="异常编号" min-width="160" />
        <el-table-column prop="buildingName" label="建筑" min-width="160" />
        <el-table-column prop="meterCode" label="表计" min-width="120" />
        <el-table-column label="类型" min-width="90">
          <template #default="{ row }">{{ TYPE[row.exceptionType] || row.exceptionType }}</template>
        </el-table-column>
        <el-table-column prop="triggerRule" label="触发规则" min-width="320" show-overflow-tooltip />
        <el-table-column label="状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'CLOSED' ? 'success' : row.status === 'HANDLING' ? 'warning' : row.status === 'IGNORED' ? 'info' : 'danger'" effect="light">
              {{ STATUS[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :disabled="row.status === 'CLOSED'" @click="open(row)">处置</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
      </div>
    </div>

    <el-drawer v-model="visible" title="异常处置" size="520px">
      <div class="card-title">异常概况</div>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="异常编号">{{ current.exceptionNo }}</el-descriptions-item>
        <el-descriptions-item label="表计">{{ current.meterCode }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ TYPE[current.exceptionType] }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ STATUS[current.status] }}</el-descriptions-item>
      </el-descriptions>
      <div class="rule">{{ current.triggerRule }}</div>
      <el-form label-width="90px" style="margin-top: 14px">
        <el-form-item label="处置方式">
          <el-radio-group v-model="form.action">
            <el-radio-button label="CLOSE">确认并关闭</el-radio-button>
            <el-radio-button label="REPAIR">转维修工单</el-radio-button>
            <el-radio-button label="IGNORE">标记误报</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="原因">
          <el-input v-model="form.cause" placeholder="如：空调季延长、管道维修补水" />
        </el-form-item>
        <el-form-item label="处置说明" required>
          <el-input v-model="form.note" type="textarea" :rows="3" maxlength="200" show-word-limit
                    placeholder="不少于 5 个字，将写入操作时间轴" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="submit">提交处置</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { readingApi } from '../api'

const TYPE = { SURGE: '突增', DROP: '突降', FLAT: '长期不变', DAMAGE: '表计损坏', CASCADE: '级联异常' }
const STATUS = { OPEN: '待处理', HANDLING: '处理中', CLOSED: '已关闭', IGNORED: '已忽略' }
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const current = ref({})
const q = reactive({ page: 1, size: 10, status: null, exceptionType: null })
const form = reactive({ action: 'CLOSE', cause: '', note: '' })

const openCount = computed(() => rows.value.filter((r) => r.status === 'OPEN').length)

async function load() {
  loading.value = true
  try {
    const d = await readingApi.exceptions({ ...q })
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}
function reload() { q.page = 1; load() }

function open(row) {
  current.value = row
  Object.assign(form, { action: 'CLOSE', cause: row.cause || '', note: row.handleNote || '' })
  visible.value = true
}

async function submit() {
  if (form.note.trim().length < 5) { ElMessage.warning('处置说明不少于 5 个字'); return }
  await readingApi.handleException(current.value.id, form)
  ElMessage.success('处置完成')
  visible.value = false
  load()
}

onMounted(load)
</script>

<style scoped>
.head { display: flex; justify-content: space-between; margin-bottom: 14px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
.rule { margin-top: 12px; background: #FBEAEC; border: 1px solid #EDC9CD; color: #8A2029; border-radius: 6px; padding: 10px 12px; font-size: 12.5px; line-height: 1.8; }
</style>

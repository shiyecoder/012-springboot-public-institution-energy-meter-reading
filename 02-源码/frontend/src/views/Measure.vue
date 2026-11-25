<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">节能措施</div>
        <div class="page-sub">在册 {{ total }} 项 · 记录投入、计划期与节能目标，验收后对比实施前后数据</div>
      </div>
      <el-button type="primary" @click="open()">登记措施</el-button>
    </div>
    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="measureNo" label="措施编号" min-width="140" />
        <el-table-column prop="measureName" label="措施名称" min-width="230" />
        <el-table-column prop="buildingName" label="实施单位" min-width="170" />
        <el-table-column prop="investAmount" label="投入(万元)" min-width="110" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.investAmount) }}</span></template>
        </el-table-column>
        <el-table-column label="计划期" min-width="190">
          <template #default="{ row }">{{ row.planStart }} ~ {{ row.planEnd }}</template>
        </el-table-column>
        <el-table-column prop="targetSaving" label="目标(tce)" min-width="110" align="right">
          <template #default="{ row }"><span class="num">{{ row.targetSaving ?? '—' }}</span></template>
        </el-table-column>
        <el-table-column prop="actualSaving" label="实际(tce)" min-width="110" align="right">
          <template #default="{ row }"><span class="num">{{ row.actualSaving ?? '—' }}</span></template>
        </el-table-column>
        <el-table-column label="状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === '已验收' ? 'success' : row.status === '实施中' ? 'warning' : 'info'" effect="light">
              {{ row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="90">
          <template #default="{ row }"><el-button link type="primary" @click="open(row)">编辑</el-button></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
      </div>
    </div>

    <el-dialog v-model="visible" :title="form.id ? '编辑措施' : '登记措施'" width="520px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="措施名称" required><el-input v-model="form.measureName" /></el-form-item>
        <el-form-item label="实施建筑">
          <el-select v-model="form.buildingId" style="width: 220px">
            <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="措施内容"><el-input v-model="form.content" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="投入(万元)"><el-input v-model="form.investAmount" /></el-form-item>
        <el-form-item label="计划期">
          <el-date-picker v-model="range" type="daterange" value-format="YYYY-MM-DD" style="width: 260px" />
        </el-form-item>
        <el-form-item label="目标(tce)"><el-input v-model="form.targetSaving" /></el-form-item>
        <el-form-item label="实际(tce)"><el-input v-model="form.actualSaving" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width: 180px">
            <el-option label="待启动" value="待启动" /><el-option label="实施中" value="实施中" />
            <el-option label="已验收" value="已验收" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { analysisApi, meterApi } from '../api'
import { num } from '../utils/format'

const rows = ref([])
const buildings = ref([])
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const range = ref([])
const q = reactive({ page: 1, size: 10 })
const form = reactive({ id: null, measureName: '', buildingId: null, content: '', investAmount: '', targetSaving: '', actualSaving: '', status: '待启动', planStart: '', planEnd: '' })

async function load() {
  loading.value = true
  try {
    const d = await analysisApi.measurePage(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

function open(row) {
  if (row) {
    Object.assign(form, row)
    range.value = [row.planStart, row.planEnd]
  } else {
    Object.assign(form, { id: null, measureName: '', buildingId: null, content: '', investAmount: '', targetSaving: '', actualSaving: '', status: '待启动', planStart: '', planEnd: '' })
    range.value = []
  }
  visible.value = true
}

async function save() {
  if (!form.measureName) { ElMessage.warning('措施名称必填'); return }
  if (range.value?.length === 2) {
    form.planStart = range.value[0]
    form.planEnd = range.value[1]
  }
  await analysisApi.saveMeasure(form)
  ElMessage.success('保存成功')
  visible.value = false
  load()
}

onMounted(async () => {
  buildings.value = await meterApi.buildings()
  load()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
</style>

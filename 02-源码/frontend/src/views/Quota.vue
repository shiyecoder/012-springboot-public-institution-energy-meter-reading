<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">能耗定额</div>
        <div class="page-sub">2026 年度 · 按建筑面积与使用人数双口径核定</div>
      </div>
      <el-button type="primary" @click="open()">新设定额</el-button>
    </div>
    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="targetName" label="用能单元" min-width="190" />
        <el-table-column label="能源" min-width="80">
          <template #default="{ row }">{{ ENERGY_LABEL[row.energyType] }}</template>
        </el-table-column>
        <el-table-column prop="periodType" label="周期" min-width="80">
          <template #default="{ row }">{{ row.periodType === 'YEAR' ? '年度' : '月度' }}</template>
        </el-table-column>
        <el-table-column prop="quotaValue" label="定额值" min-width="120" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.quotaValue, 0) }}</span></template>
        </el-table-column>
        <el-table-column prop="usedValue" label="已用量" min-width="120" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.usedValue, 0) }}</span></template>
        </el-table-column>
        <el-table-column label="使用进度" min-width="180">
          <template #default="{ row }">
            <el-progress :percentage="Math.min(row.rate, 100)"
                         :status="row.rate > 100 ? 'exception' : row.rate > 85 ? 'warning' : 'success'"
                         :stroke-width="7" />
          </template>
        </el-table-column>
        <el-table-column label="达标情况" min-width="110">
          <template #default="{ row }">
            <el-tag :type="row.state === '超定额' ? 'danger' : row.state === '接近预警' ? 'warning' : 'success'" effect="light">
              {{ row.state }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="90">
          <template #default="{ row }"><el-button link type="primary" @click="open(row)">调整</el-button></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
      </div>
    </div>

    <el-dialog v-model="visible" :title="form.id ? '调整定额' : '新设定额'" width="480px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="定额对象" required>
          <el-select v-model="form.targetId" filterable allow-create style="width: 260px"
                     @change="pick">
            <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="能源类型">
          <el-select v-model="form.energyType" style="width: 200px">
            <el-option label="电" value="ELEC" /><el-option label="水" value="WATER" />
            <el-option label="燃气" value="GAS" />
          </el-select>
        </el-form-item>
        <el-form-item label="定额周期">
          <el-select v-model="form.periodType" style="width: 200px">
            <el-option label="年度" value="YEAR" /><el-option label="月度" value="MONTH" />
          </el-select>
        </el-form-item>
        <el-form-item label="定额值" required>
          <el-input v-model="form.quotaValue" />
        </el-form-item>
        <el-form-item label="年度">
          <el-input v-model="form.year" />
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
import { ENERGY_LABEL, num } from '../utils/format'

const rows = ref([])
const buildings = ref([])
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const q = reactive({ page: 1, size: 10 })
const form = reactive({ id: null, targetId: null, targetName: '', targetType: 'BUILDING', energyType: 'ELEC', periodType: 'YEAR', quotaValue: '', year: 2026 })

async function load() {
  loading.value = true
  try {
    const d = await analysisApi.quotaPage(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

function open(row) {
  if (row) Object.assign(form, row)
  else Object.assign(form, { id: null, targetId: null, targetName: '', targetType: 'BUILDING', energyType: 'ELEC', periodType: 'YEAR', quotaValue: '', year: 2026 })
  visible.value = true
}

function pick(id) {
  const b = buildings.value.find((x) => x.id === id)
  form.targetName = b ? b.buildingName : ''
}

async function save() {
  if (!form.targetName || !form.quotaValue) { ElMessage.warning('定额对象与定额值必填'); return }
  await analysisApi.saveQuota(form)
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

<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">表计资产台账</div>
        <div class="page-sub">共 {{ total }} 台表计 · 覆盖 8 栋建筑 10 个用能单元</div>
      </div>
      <div class="ops">
        <el-button :icon="Upload" @click="importTip">导入台账</el-button>
        <el-button type="primary" :icon="Plus" @click="openForm()">新增表计</el-button>
      </div>
    </div>

    <div class="filter-bar">
      <el-select v-model="q.buildingId" placeholder="全部建筑" clearable style="width: 200px" @change="reload">
        <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
      </el-select>
      <el-select v-model="q.energyType" placeholder="全部类型" clearable style="width: 180px" @change="reload">
        <el-option label="电" value="ELEC" /><el-option label="水" value="WATER" />
        <el-option label="燃气" value="GAS" /><el-option label="冷热量" value="COOL" />
      </el-select>
      <el-select v-model="q.status" placeholder="全部状态" clearable style="width: 180px" @change="reload">
        <el-option label="在用" value="在用" /><el-option label="停用" value="停用" />
        <el-option label="待检定" value="待检定" />
      </el-select>
      <el-input v-model="q.keyword" placeholder="表计编号 / 安装位置" clearable style="width: 220px"
                @keyup.enter="reload" />
      <el-button type="primary" @click="reload">查询</el-button>
      <el-button @click="reset">重置</el-button>
      <el-button link type="primary" @click="drawerFilter = true">高级筛选</el-button>
    </div>

    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading" style="width: 100%">
        <el-table-column prop="meterCode" label="表计编号" min-width="140">
          <template #default="{ row }"><span class="num">{{ row.meterCode }}</span></template>
        </el-table-column>
        <el-table-column label="能源类型" min-width="90">
          <template #default="{ row }">{{ ENERGY_LABEL[row.energyType] }}</template>
        </el-table-column>
        <el-table-column prop="buildingName" label="所属建筑" min-width="170" />
        <el-table-column prop="installLocation" label="安装位置" min-width="170" />
        <el-table-column prop="unitName" label="单位" min-width="70" />
        <el-table-column prop="ratio" label="倍率" min-width="70" align="right" />
        <el-table-column prop="lastReading" label="上期读数" min-width="120" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.lastReading) }}</span></template>
        </el-table-column>
        <el-table-column label="表计状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === '在用' ? 'success' : 'info'" effect="light">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="抄表周期" min-width="90">
          <template #default="{ row }">{{ row.cycleType === 'MONTH' ? '月度' : '季度' }}</template>
        </el-table-column>
        <el-table-column label="异常标记" min-width="100">
          <template #default="{ row }">
            <el-tag :type="row.abnormalFlag === '正常' ? 'success' : 'danger'" effect="light">{{ row.abnormalFlag }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">查看</el-button>
            <el-button link type="primary" @click="openForm(row)">编辑</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
                       :total="total" :page-size="q.size" :current-page="q.page"
                       :page-sizes="[10, 20, 50]"
                       @current-change="(p) => { q.page = p; load() }"
                       @size-change="(s) => { q.size = s; q.page = 1; load() }" />
      </div>
    </div>

    <el-drawer v-model="drawerFilter" title="高级筛选" size="420px">
      <el-form label-width="100px">
        <el-form-item label="抄表周期">
          <el-select v-model="q.cycleType" clearable style="width: 220px">
            <el-option label="月度" value="MONTH" /><el-option label="季度" value="QUARTER" />
          </el-select>
        </el-form-item>
        <el-form-item label="异常标记">
          <el-select v-model="q.abnormalFlag" clearable style="width: 220px">
            <el-option label="正常" value="正常" /><el-option label="突增" value="突增" />
            <el-option label="偏高" value="偏高" /><el-option label="表计损坏" value="表计损坏" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="drawerFilter = false">取消</el-button>
        <el-button type="primary" @click="applyAdvanced">应用筛选</el-button>
      </template>
    </el-drawer>

    <el-drawer v-model="drawerForm" :title="form.id ? '编辑表计' : '新增表计'" size="560px">
      <el-form :model="form" label-width="110px">
        <el-form-item label="表计编号" required>
          <el-input v-model="form.meterCode" maxlength="50" show-word-limit placeholder="如 EM-D-0701" />
        </el-form-item>
        <el-form-item label="能源类型" required>
          <el-select v-model="form.energyType" style="width: 220px">
            <el-option label="电" value="ELEC" /><el-option label="水" value="WATER" />
            <el-option label="燃气" value="GAS" /><el-option label="冷热量" value="COOL" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属建筑" required>
          <el-select v-model="form.buildingId" style="width: 240px">
            <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="安装位置" required>
          <el-input v-model="form.installLocation" placeholder="如 B1 配电房 3#柜" />
        </el-form-item>
        <el-form-item label="计量单位" required>
          <el-select v-model="form.unitName" style="width: 200px">
            <el-option label="kWh" value="kWh" /><el-option label="m³" value="m³" />
            <el-option label="GJ" value="GJ" /><el-option label="t" value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="倍率" required>
          <el-input-number v-model="form.ratio" :min="1" :step="1" style="width: 200px" />
        </el-form-item>
        <el-form-item label="抄表周期">
          <el-select v-model="form.cycleType" style="width: 200px">
            <el-option label="月度" value="MONTH" /><el-option label="季度" value="QUARTER" />
          </el-select>
        </el-form-item>
        <el-form-item label="表计状态">
          <el-select v-model="form.status" style="width: 200px">
            <el-option label="在用" value="在用" /><el-option label="停用" value="停用" />
            <el-option label="待检定" value="待检定" />
          </el-select>
        </el-form-item>
        <el-form-item label="上期读数">
          <el-input v-model="form.lastReading" placeholder="按表盘实际读数填写" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="drawerForm = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-drawer>

    <el-drawer v-model="drawerDetail" title="表计详情" size="640px">
      <template v-if="detail.meter">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="表计编号">{{ detail.meter.meterCode }}</el-descriptions-item>
          <el-descriptions-item label="能源类型">{{ ENERGY_LABEL[detail.meter.energyType] }}</el-descriptions-item>
          <el-descriptions-item label="所属建筑">{{ detail.building?.buildingName }}</el-descriptions-item>
          <el-descriptions-item label="安装位置">{{ detail.meter.installLocation }}</el-descriptions-item>
          <el-descriptions-item label="倍率">{{ detail.meter.ratio }}</el-descriptions-item>
          <el-descriptions-item label="上期读数">{{ num(detail.meter.lastReading) }}</el-descriptions-item>
          <el-descriptions-item label="状态">{{ detail.meter.status }}</el-descriptions-item>
          <el-descriptions-item label="安装日期">{{ detail.meter.installDate }}</el-descriptions-item>
        </el-descriptions>
        <div class="card-title" style="margin-top: 18px">最近抄表任务</div>
        <el-table :data="detail.tasks || []" size="small">
          <el-table-column prop="taskNo" label="任务编号" min-width="150" />
          <el-table-column prop="period" label="周期" min-width="90" />
          <el-table-column label="状态" min-width="100">
            <template #default="{ row }">
              <el-tag :type="taskType(row.status)" effect="light">{{ taskLabel(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="deadline" label="截止日期" min-width="110" />
        </el-table>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Upload } from '@element-plus/icons-vue'
import { meterApi } from '../api'
import { ENERGY_LABEL, num, taskLabel, taskType } from '../utils/format'

const rows = ref([])
const buildings = ref([])
const total = ref(0)
const loading = ref(false)
const saving = ref(false)
const drawerForm = ref(false)
const drawerDetail = ref(false)
const drawerFilter = ref(false)
const detail = ref({})
const q = reactive({ page: 1, size: 10, buildingId: null, energyType: null, status: null, cycleType: null, abnormalFlag: null, keyword: '' })
const empty = () => ({ meterCode: '', energyType: 'ELEC', buildingId: null, installLocation: '', unitName: 'kWh', ratio: 1, cycleType: 'MONTH', status: '在用', lastReading: 0 })
const form = reactive(empty())

async function load() {
  loading.value = true
  try {
    const d = await meterApi.page({ ...q, keyword: q.keyword || undefined })
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

function reload() { q.page = 1; load() }
function applyAdvanced() { drawerFilter.value = false; reload() }

function reset() {
  Object.assign(q, { page: 1, buildingId: null, energyType: null, status: null, cycleType: null, abnormalFlag: null, keyword: '' })
  load()
}

function openForm(row) {
  if (row) {
    Object.assign(form, row)
    form.updateTime = row.updateTime
  } else {
    Object.assign(form, empty())
  }
  drawerForm.value = true
}

async function openDetail(row) {
  detail.value = await meterApi.detail(row.id)
  drawerDetail.value = true
}

async function save() {
  if (!form.meterCode || !form.buildingId || !form.installLocation) {
    ElMessage.warning('表计编号、所属建筑、安装位置必填')
    return
  }
  saving.value = true
  try {
    if (form.id) await meterApi.update(form.id, form)
    else await meterApi.save(form)
    ElMessage.success('保存成功')
    drawerForm.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function remove(row) {
  await ElMessageBox.confirm(`确认删除表计 ${row.meterCode}？删除后不可恢复。`, '删除确认', { type: 'warning' })
  await meterApi.remove(row.id)
  ElMessage.success('已删除')
  load()
}

function importTip() { ElMessage.info('台账导入模板：表计编号 / 能源类型 / 建筑 / 安装位置 / 倍率') }

onMounted(async () => {
  buildings.value = await meterApi.buildings()
  load()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.ops { display: flex; gap: 10px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
</style>

<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">费用台账</div>
        <div class="page-sub">计费规则版本 v2026.10 · 账单生成后锁定对应抄表记录</div>
      </div>
      <div class="ops">
        <el-select v-model="period" style="width: 160px">
          <el-option v-for="p in periods" :key="p" :label="p" :value="p" />
        </el-select>
        <el-button type="primary" @click="doGenerate">生成本月账单</el-button>
      </div>
    </div>
    <div class="card" style="padding: 0; margin-bottom: 12px">
      <el-table :data="rows" v-loading="loading">
        <el-table-column prop="billNo" label="账单编号" min-width="160" />
        <el-table-column prop="buildingName" label="建筑" min-width="170" />
        <el-table-column label="能源" min-width="80">
          <template #default="{ row }">{{ ENERGY_LABEL[row.energyType] }}</template>
        </el-table-column>
        <el-table-column prop="usageAmount" label="用量" min-width="110" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.usageAmount) }}</span></template>
        </el-table-column>
        <el-table-column prop="unitPrice" label="单价" min-width="90" align="right" />
        <el-table-column label="金额" min-width="120" align="right">
          <template #default="{ row }"><span class="num">{{ money(row.finalAmount) }}</span></template>
        </el-table-column>
        <el-table-column label="状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === '已调整' ? 'danger' : row.status === '已锁定' ? 'info' : 'success'" effect="light">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="90" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openAdjust(row)">调整</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
      </div>
    </div>
    <div class="card">
      <div class="card-title">计费规则</div>
      <el-table :data="tariffs" size="small">
        <el-table-column prop="ruleName" label="规则名称" min-width="220" />
        <el-table-column label="能源" min-width="80">
          <template #default="{ row }">{{ ENERGY_LABEL[row.energyType] }}</template>
        </el-table-column>
        <el-table-column label="计费方式" min-width="100">
          <template #default="{ row }">{{ row.chargeType === 'LADDER' ? '阶梯' : '固定单价' }}</template>
        </el-table-column>
        <el-table-column prop="price" label="单价" min-width="90" align="right" />
        <el-table-column prop="effectiveDate" label="生效日期" min-width="110" />
        <el-table-column prop="version" label="版本" min-width="100" />
        <el-table-column label="状态" min-width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ENABLED' ? 'success' : 'info'" effect="light">
              {{ row.status === 'ENABLED' ? '生效中' : '已停用' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog v-model="visible" title="手工调整账单" width="460px">
      <el-form label-width="90px">
        <el-form-item label="账单编号">{{ current.billNo }}</el-form-item>
        <el-form-item label="原金额">{{ money(current.amount) }}</el-form-item>
        <el-form-item label="调整金额">
          <el-input v-model="adjust.adjustAmount" placeholder="正数增加、负数减少" />
        </el-form-item>
        <el-form-item label="调整原因" required>
          <el-input v-model="adjust.reason" type="textarea" :rows="2" placeholder="不少于 5 个字" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="doAdjust">提交审批</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { billApi } from '../api'
import { ENERGY_LABEL, money, num } from '../utils/format'

const rows = ref([])
const tariffs = ref([])
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const current = ref({})
const period = ref('2026-10')
const periods = ['2026-10', '2026-09', '2026-08', '2026-07']
const q = reactive({ page: 1, size: 10, period: '2026-10' })
const adjust = reactive({ adjustAmount: '', reason: '' })

async function load() {
  loading.value = true
  try {
    q.period = period.value
    const d = await billApi.page(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

async function doGenerate() {
  const d = await billApi.generate(period.value)
  ElMessage.success(`已生成 ${d.created} 张账单，合计 ${money(d.totalAmount)}`)
  load()
}

function openAdjust(row) {
  current.value = row
  Object.assign(adjust, { adjustAmount: '', reason: '' })
  visible.value = true
}

async function doAdjust() {
  if (adjust.reason.trim().length < 5) { ElMessage.warning('调整原因不少于 5 个字'); return }
  await billApi.adjust(current.value.id, adjust)
  ElMessage.success('调整已提交')
  visible.value = false
  load()
}

onMounted(async () => {
  tariffs.value = await billApi.tariffs()
  load()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.ops { display: flex; gap: 10px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
</style>

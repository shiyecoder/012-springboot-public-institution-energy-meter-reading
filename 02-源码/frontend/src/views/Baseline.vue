<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">能耗基线偏差识别</div>
        <div class="page-sub">规则 {{ rule.rule?.version || 'v3' }} · 6 因子加权（合计 100%）· 每次计算留痕可追溯</div>
      </div>
      <div class="ops">
        <el-button @click="ruleVisible = true">规则配置</el-button>
        <el-button type="primary" @click="doEvaluate">执行识别</el-button>
      </div>
    </div>

    <div class="grid">
      <div class="card">
        <div class="card-title">计算对象</div>
        <el-form label-width="90px">
          <el-form-item label="建筑">
            <el-select v-model="req.buildingId" filterable style="width: 220px">
              <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="能源">
            <el-select v-model="req.energyType" style="width: 180px">
              <el-option label="电" value="ELEC" /><el-option label="水" value="WATER" />
            </el-select>
          </el-form-item>
          <el-form-item label="周期">
            <el-input v-model="req.period" placeholder="2026-10" style="width: 180px" />
          </el-form-item>
          <el-form-item label="权重合计">
            <el-tag type="success" effect="light">{{ weightSum }}%</el-tag>
          </el-form-item>
        </el-form>
        <div class="wlist">
          <div v-for="f in factors" :key="f.key" class="wrow">
            <span>{{ f.label }}</span><b class="num">{{ weightOf(f.key) }}%</b>
          </div>
        </div>
      </div>

      <div class="card result" v-if="result">
        <div class="score">
          <div class="muted">综合偏差得分</div>
          <div class="big num" :class="result.level === 'HIGH' ? 'up' : result.level === 'MID' ? 'mid' : 'down'">
            {{ result.totalScore }}
          </div>
          <el-tag :type="LEVEL_TYPE[result.level]" effect="light" size="large">{{ result.levelLabel }}</el-tag>
          <div class="muted small">{{ result.scoreNo }} · {{ result.period }} · {{ result.meterCode }}</div>
        </div>
        <div class="explain">
          <div class="etitle">结论</div>
          <p>{{ result.conclusion }}</p>
          <div class="etitle">主要影响因素</div>
          <ul><li v-for="f in result.mainFactors" :key="f">{{ f }}</li></ul>
          <div class="etitle">未满足条件</div>
          <ul class="warn"><li v-for="u in result.unmet" :key="u">{{ u }}</li></ul>
          <div class="etitle">可改进项</div>
          <ul class="ok"><li v-for="i in result.improve" :key="i">{{ i }}</li></ul>
        </div>
      </div>
      <div class="card empty" v-else>
        <el-empty description="选择建筑后点击「执行识别」，系统按近 6 期基线计算偏差" />
      </div>
    </div>

    <div class="card" style="margin-top: 12px" v-if="result">
      <div class="card-title">因子明细（按规则 {{ result.ruleVersion }} 权重）</div>
      <el-table :data="result.items" size="small">
        <el-table-column prop="label" label="输入因子" min-width="140" />
        <el-table-column prop="weight" label="权重" min-width="80" align="right">
          <template #default="{ row }">{{ row.weight }}%</template>
        </el-table-column>
        <el-table-column prop="score" label="得分" min-width="80" align="right" />
        <el-table-column label="得分强度" min-width="200">
          <template #default="{ row }">
            <el-progress :percentage="Math.min(row.score, 100)" :stroke-width="8"
                         :status="row.score >= 75 ? 'exception' : row.score >= 50 ? 'warning' : 'success'" />
          </template>
        </el-table-column>
        <el-table-column prop="note" label="计算说明" min-width="360" show-overflow-tooltip />
      </el-table>
      <div class="snap">
        输入快照：本期 {{ result.input.currUsage }}，基线均值 {{ result.input.baseMean }}，
        标准差 {{ result.input.baseStd }}，面积 {{ result.input.buildArea }} ㎡，
        人数 {{ result.input.personCount }}，季节系数 {{ result.input.seasonFactor }}
      </div>
    </div>

    <div class="card" style="margin-top: 12px">
      <div class="card-title">
        <span>历史计算记录</span>
        <span class="muted small">推荐采纳率 {{ stat.adoptRate }}% · 人工调整率 {{ stat.adjustRate }}%</span>
      </div>
      <el-table :data="rows" v-loading="loading" size="small">
        <el-table-column prop="scoreNo" label="计算编号" min-width="150" />
        <el-table-column prop="buildingName" label="建筑" min-width="160" />
        <el-table-column prop="period" label="周期" min-width="90" />
        <el-table-column prop="totalScore" label="得分" min-width="80" align="right" />
        <el-table-column label="系统结论" min-width="100">
          <template #default="{ row }">
            <el-tag :type="LEVEL_TYPE[row.level]" effect="light">{{ row.levelLabel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="人工修正" min-width="200">
          <template #default="{ row }">
            <span v-if="row.adjustLevel" class="muted">{{ LEVEL_LABEL[row.adjustLevel] }} · {{ row.adjustReason }}</span>
            <span v-else class="muted">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="calcTime" label="计算时间" min-width="160">
          <template #default="{ row }">{{ formatTime(row.calcTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="100">
          <template #default="{ row }"><el-button link type="primary" @click="openAdjust(row)">人工修正</el-button></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; loadScores() }" />
      </div>
    </div>

    <el-dialog v-model="ruleVisible" title="规则配置（权重合计必须等于 100%）" width="560px">
      <el-form label-width="120px">
        <el-form-item v-for="f in factors" :key="f.key" :label="f.label">
          <el-input-number v-model="weights[f.key]" :min="0" :max="100" :step="5" style="width: 160px" />
          <span class="muted" style="margin-left: 8px">%</span>
        </el-form-item>
        <el-form-item label="合计">
          <el-tag :type="weightSum === 100 ? 'success' : 'danger'">{{ weightSum }}%</el-tag>
        </el-form-item>
        <el-form-item label="等级阈值">
          <el-input-number v-model="thresholds.high" :min="0" :max="100" style="width: 120px" />
          <span class="muted" style="margin: 0 8px">以上为突增</span>
          <el-input-number v-model="thresholds.mid" :min="0" :max="100" style="width: 120px" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="ruleVisible = false">取消</el-button>
        <el-button type="primary" @click="saveRule">保存并生成新版本</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="adjustVisible" title="人工修正" width="460px">
      <el-form label-width="90px">
        <el-form-item label="系统结论">{{ current.levelLabel }}</el-form-item>
        <el-form-item label="修正为">
          <el-radio-group v-model="adjust.level">
            <el-radio-button label="HIGH">突增</el-radio-button>
            <el-radio-button label="MID">偏高</el-radio-button>
            <el-radio-button label="LOW">正常</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="修正原因" required>
          <el-input v-model="adjust.reason" type="textarea" :rows="3" placeholder="不少于 5 个字，原始计算结果不会被覆盖" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="adjustVisible = false">取消</el-button>
        <el-button type="primary" @click="doAdjust">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { baselineApi, meterApi } from '../api'
import { formatTime, LEVEL_LABEL, LEVEL_TYPE } from '../utils/format'

const buildings = ref([])
const rows = ref([])
const total = ref(0)
const loading = ref(false)
const result = ref(null)
const rule = ref({})
const factors = ref([])
const stat = ref({})
const ruleVisible = ref(false)
const adjustVisible = ref(false)
const current = ref({})
const req = reactive({ buildingId: null, energyType: 'ELEC', period: '2026-10' })
const weights = reactive({})
const thresholds = reactive({ high: 75, mid: 50 })
const q = reactive({ page: 1, size: 10 })
const adjust = reactive({ level: 'MID', reason: '' })

const weightSum = computed(() => Object.values(weights).reduce((a, b) => a + (Number(b) || 0), 0))
const weightOf = (k) => words(k)
function words(k) { return weights[k] ?? 0 }

async function loadRule() {
  const d = await baselineApi.rule()
  rule.value = d
  factors.value = d.factors || []
  Object.assign(weights, d.weights || {})
  Object.assign(thresholds, d.thresholds || { high: 75, mid: 50 })
}

async function loadScores() {
  loading.value = true
  try {
    const d = await baselineApi.page(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

async function doEvaluate() {
  if (!req.buildingId) { ElMessage.warning('请选择建筑'); return }
  result.value = await baselineApi.evaluate({ ...req })
  ElMessage.success('识别完成，结果已留痕')
  loadScores()
  stat.value = await baselineApi.stat()
}

async function saveRule() {
  if (weightSum.value !== 100) { ElMessage.warning('权重合计必须等于 100%'); return }
  const d = await baselineApi.saveRule({ ruleName: '能耗基线偏差识别', weights: { ...weights }, thresholds: { ...thresholds } })
  ElMessage.success('已保存新版本 ' + d.version)
  ruleVisible.value = false
  await loadRule()
}

function openAdjust(row) {
  current.value = row
  adjust.level = row.level
  adjust.reason = ''
  adjustVisible.value = true
}

async function doAdjust() {
  if (adjust.reason.trim().length < 5) { ElMessage.warning('修正原因不少于 5 个字'); return }
  await baselineApi.adjust(current.value.id, { ...adjust })
  ElMessage.success('修正成功')
  adjustVisible.value = false
  loadScores()
}

onMounted(async () => {
  buildings.value = await meterApi.buildings()
  req.buildingId = buildings.value[2]?.id || buildings.value[0]?.id
  await loadRule()
  loadScores()
  stat.value = await baselineApi.stat()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.ops { display: flex; gap: 10px; }
.grid { display: grid; grid-template-columns: 300px 1fr; gap: 12px; align-items: start; }
.wlist { border-top: 1px solid #EDF4F4; margin-top: 6px; padding-top: 10px; }
.wrow { display: flex; justify-content: space-between; font-size: 12px; color: var(--c-text-2); padding: 3px 0; }
.wrow b { color: var(--c-primary); }
.result { display: grid; grid-template-columns: 190px 1fr; gap: 18px; }
.score { text-align: center; border-right: 1px solid #EDF4F4; padding-right: 12px; }
.big { font-size: 44px; font-weight: 600; line-height: 1.2; margin: 4px 0; }
.big.mid { color: #A66A1E; }
.small { font-size: 11px; margin-top: 8px; }
.explain p { font-size: 12.5px; line-height: 1.85; margin: 4px 0 10px; }
.explain ul { margin: 4px 0 10px; padding-left: 18px; font-size: 12.5px; line-height: 1.8; }
.explain ul.warn { color: #8A2029; }
.explain ul.ok { color: #1B5A3E; }
.etitle { font-size: 12px; font-weight: 500; color: var(--c-text-2); }
.empty { display: flex; align-items: center; justify-content: center; min-height: 300px; }
.snap { margin-top: 10px; font-size: 12px; color: var(--c-text-2); background: #F5FAFA; border-radius: 6px; padding: 10px 12px; line-height: 1.8; }
.pager { display: flex; justify-content: flex-end; padding-top: 10px; }
</style>

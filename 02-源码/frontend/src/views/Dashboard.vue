<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">节能分析看板</div>
        <div class="page-sub">数据口径：{{ periodText }} · 上次更新 {{ now }}</div>
      </div>
      <div class="ops">
        <el-select v-model="period" style="width: 180px" @change="load">
          <el-option label="本月（2026-10）" value="2026-10" />
          <el-option label="上月（2026-09）" value="2026-09" />
          <el-option label="全部周期" value="" />
        </el-select>
        <el-button :icon="Download" @click="exportCsv">导出报表</el-button>
      </div>
    </div>

    <div class="kpi-grid">
      <div class="kpi">
        <div class="kpi-label">总能耗</div>
        <div class="kpi-value num">{{ num(kpi.totalUsage, 1) }}<small>万kWh</small></div>
        <div class="kpi-desc">含电、水、燃气与冷热量折标</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">单位面积能耗</div>
        <div class="kpi-value num">{{ kpi.areaUsage }}<small>kWh/㎡</small></div>
        <div class="kpi-desc">电力口径 / 总建筑面积 14.3 万㎡</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">本期费用</div>
        <div class="kpi-value num">{{ num(kpi.billAmount, 0) }}<small>元</small></div>
        <div class="kpi-desc">按现行计费规则 v2026.10</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">异常表计</div>
        <div class="kpi-value num">{{ kpi.exceptionCount }}<small>台</small></div>
        <div class="kpi-desc">待复核与处理中合计</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">定额达标率</div>
        <div class="kpi-value num">{{ kpi.quotaRate }}<small>%</small></div>
        <div class="kpi-desc">年度定额未超标的单位占比</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">在用量表计</div>
        <div class="kpi-value num">{{ kpi.meterCount }}<small>台</small></div>
        <div class="kpi-desc">覆盖 8 栋建筑 10 个用能单元</div>
      </div>
    </div>

    <div class="row1">
      <div class="card">
        <div class="card-title">
          <span>月度能耗趋势</span>
          <span class="legend">
            <i style="background:#0F4C5C"></i>电 <i style="background:#2A7F86"></i>水
            <i style="background:#7FA6A9"></i>燃气
          </span>
        </div>
        <EChart :option="trendOption" :height="230" />
      </div>
      <div class="card">
        <div class="card-title"><span>能源类型占比</span></div>
        <EChart :option="typeOption" :height="230" />
      </div>
      <div class="card">
        <div class="card-title"><span>建筑能耗排名 TOP6</span></div>
        <EChart :option="rankOption" :height="230" />
      </div>
    </div>

    <div class="row2">
      <div class="card">
        <div class="card-title"><span>抄表任务状态分布</span></div>
        <EChart :option="taskOption" :height="165" />
      </div>
      <div class="card">
        <div class="card-title"><span>单位面积能耗 TOP6</span>
          <span class="unit">kWh/㎡</span>
        </div>
        <EChart :option="unitOption" :height="165" />
      </div>
      <div class="card">
        <div class="card-title"><span>能耗基线识别结果</span>
          <el-button link type="primary" @click="$router.push('/baseline')">查看明细</el-button>
        </div>
        <EChart :option="baseOption" :height="112" />
        <div class="lv-row">
          <div class="lv lv-h"><span>突增</span><b class="num">{{ base.high }}</b></div>
          <div class="lv lv-m"><span>偏高</span><b class="num">{{ base.mid }}</b></div>
          <div class="lv lv-l"><span>正常</span><b class="num">{{ base.low }}</b></div>
        </div>
        <div class="base-foot">
          <span>采纳率 <b class="num">{{ base.adoptRate }}%</b></span>
          <span>调整率 <b class="num">{{ base.adjustRate }}%</b></span>
          <span>计算 <b class="num">{{ base.total }}</b> 次</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { Download } from '@element-plus/icons-vue'
import EChart from '../components/EChart.vue'
import { analysisApi } from '../api'
import { num } from '../utils/format'

const period = ref('2026-10')
const kpi = ref({})
const byType = ref({})
const trend = ref({})
const rank = ref([])
const tasks = ref({})
const base = ref({})
const now = ref('')

const periodText = computed(() => (period.value ? period.value.replace('-', ' 年 ') + ' 月' : '全部周期'))

const TREndColors = { ELEC: '#0F4C5C', WATER: '#2A7F86', GAS: '#315F66', COOL: '#7FA6A9' }

const trendOption = computed(() => {
  const months = Object.keys(trend.value).sort()
  return {
    grid: { left: 44, right: 16, top: 16, bottom: 28 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: months.map((m) => m.slice(5) + '月'), axisLine: { lineStyle: { color: '#DCE7E8' } }, axisLabel: { color: '#5C7379', fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { color: '#5C7379', fontSize: 11 }, splitLine: { lineStyle: { color: '#E8F0F0', type: 'dashed' } } },
    series: [{
      type: 'line', smooth: true, symbolSize: 5,
      data: months.map((m) => trend.value[m]),
      itemStyle: { color: '#0F4C5C' }, lineStyle: { width: 2 },
      areaStyle: { color: 'rgba(15,76,92,.06)' }
    }]
  }
})

const typeOption = computed(() => {
  const names = { ELEC: '电', WATER: '水', GAS: '燃气', COOL: '冷热量' }
  const data = Object.entries(byType.value).map(([k, v]) => ({
    name: names[k] || k, value: Math.round(v), itemStyle: { color: TREndColors[k] }
  }))
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#5C7379' } },
    series: [{
      type: 'pie', radius: ['52%', '72%'], center: ['50%', '44%'],
      data, label: { show: false },
      emphasis: { label: { show: true, fontSize: 12, formatter: '{b}\n{d}%' } }
    }]
  }
})

const rankOption = computed(() => {
  const list = [...rank.value].reverse()
  return {
    grid: { left: 96, right: 40, top: 10, bottom: 10 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    xAxis: { type: 'value', axisLabel: { show: false }, splitLine: { show: false } },
    yAxis: { type: 'category', data: list.map((x) => x.name), axisLabel: { fontSize: 11, color: '#16323A' }, axisLine: { show: false }, axisTick: { show: false } },
    series: [{
      type: 'bar', barWidth: 14,
      data: list.map((x) => x.value),
      itemStyle: { color: '#2A7F86', borderRadius: [0, 2, 2, 0] },
      label: { show: true, position: 'right', fontSize: 10, color: '#5C7379', formatter: (p) => Math.round(p.value) }
    }]
  }
})

const taskOption = computed(() => ({
  grid: { left: 36, right: 12, top: 16, bottom: 26 },
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: Object.keys(tasks.value), axisLabel: { fontSize: 11, color: '#5C7379' }, axisLine: { lineStyle: { color: '#DCE7E8' } } },
  yAxis: { type: 'value', splitLine: { lineStyle: { color: '#E8F0F0', type: 'dashed' } }, axisLabel: { fontSize: 11, color: '#5C7379' } },
  series: [{
    type: 'bar', barWidth: 26, data: Object.values(tasks.value),
    itemStyle: { color: '#0F4C5C', borderRadius: [2, 2, 0, 0] }
  }]
}))

// 单位面积能耗排名：由后端按 buildingRank 的 unitUsage 直接给出，前端不做二次聚合
const unitOption = computed(() => {
  const list = [...rank.value].sort((a, b) => (b.unitUsage || 0) - (a.unitUsage || 0))
  return {
    grid: { left: 92, right: 44, top: 8, bottom: 6 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    xAxis: { type: 'value', axisLabel: { show: false }, splitLine: { show: false } },
    yAxis: {
      type: 'category',
      data: list.map((x) => x.name),
      axisLabel: { fontSize: 10.5, color: '#16323A', width: 84, overflow: 'truncate' },
      axisLine: { show: false }, axisTick: { show: false }
    },
    series: [{
      type: 'bar', barWidth: 12,
      data: list.map((x) => x.unitUsage || 0),
      itemStyle: { color: '#315F66', borderRadius: [0, 2, 2, 0] },
      label: { show: true, position: 'right', fontSize: 10, color: '#5C7379' }
    }]
  }
})

// 基线识别结果环图（不只用红黄绿标签，同时给出分布与采纳/调整率）
const baseOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}：{c} 条（{d}%）' },
  series: [{
    type: 'pie', radius: ['56%', '76%'], center: ['50%', '52%'],
    data: [
      { name: '突增', value: base.value.high || 0, itemStyle: { color: '#B02A37' } },
      { name: '偏高', value: base.value.mid || 0, itemStyle: { color: '#C98A2E' } },
      { name: '正常', value: base.value.low || 0, itemStyle: { color: '#247451' } }
    ],
    label: { show: false },
    emphasis: { label: { show: true, fontSize: 11, formatter: '{b}\n{c}' } }
  }]
}))

function exportCsv() {
  const rows = [['指标', '数值'], ['总能耗', kpi.value.totalUsage], ['单位面积能耗', kpi.value.areaUsage],
    ['本期费用', kpi.value.billAmount], ['异常表计', kpi.value.exceptionCount], ['定额达标率', kpi.value.quotaRate]]
  const csv = rows.map((r) => r.join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `节能分析看板-${period.value || 'all'}.csv`
  a.click()
}

async function load() {
  const d = await analysisApi.dashboard(period.value || undefined)
  kpi.value = d.kpi
  byType.value = d.byType
  trend.value = d.trend
  rank.value = d.buildingRank
  tasks.value = d.taskStat
  base.value = d.baseline
}

onMounted(() => {
  const d = new Date()
  now.value = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  load()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.ops { display: flex; gap: 10px; }
.row1 { display: grid; grid-template-columns: 1.5fr 1fr 1fr; gap: 12px; }
.row2 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-top: 12px; }
.unit { font-size: 11px; color: #8FA6AB; font-weight: 400; }
.legend { font-size: 11px; color: var(--c-text-2); display: flex; align-items: center; gap: 5px; font-weight: 400; }
.legend i { display: inline-block; width: 8px; height: 8px; border-radius: 2px; margin-left: 6px; }
.lv-row { display: flex; gap: 8px; margin: 2px 0 8px; }
.lv { flex: 1; border-radius: 6px; padding: 5px 8px; }
.lv span { font-size: 11px; }
.lv b { display: block; font-size: 17px; margin-top: 1px; }
.lv-h { background: #FBEAEC; color: #B02A37; }
.lv-m { background: #FBF1E2; color: #A66A1E; }
.lv-l { background: #E7F2EC; color: #247451; }
.base-foot { display: flex; justify-content: space-between; font-size: 11.5px; color: var(--c-text-2); border-top: 1px solid #EDF4F4; padding-top: 7px; }
.base-foot b { color: var(--c-primary); }
.base-note { font-size: 11.5px; color: #8FA6AB; margin-top: 10px; line-height: 1.7; }
@media (max-width: 1400px) { .row1, .row2 { grid-template-columns: 1fr 1fr; } }
</style>

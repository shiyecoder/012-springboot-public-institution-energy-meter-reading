// 全局时间与数字格式化：全系统统一调用，禁止各页面重复实现
export function formatTime(v) {
  if (!v) return '—'
  const s = String(v).replace('T', ' ')
  return s.length >= 19 ? s.slice(0, 19) : s
}

export function formatDate(v) {
  if (!v) return '—'
  return String(v).slice(0, 10)
}

export function money(v) {
  if (v === null || v === undefined || v === '') return '—'
  return '¥' + Number(v).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export function num(v, digits = 2) {
  if (v === null || v === undefined || v === '') return '—'
  return Number(v).toLocaleString('zh-CN', { minimumFractionDigits: digits, maximumFractionDigits: digits })
}

export const ENERGY_LABEL = { ELEC: '电', WATER: '水', GAS: '燃气', COOL: '冷热量' }
export const ENERGY_UNIT = { ELEC: 'kWh', WATER: 'm³', GAS: 'm³', COOL: 'GJ' }
export const LEVEL_LABEL = { HIGH: '突增', MID: '偏高', LOW: '正常' }
export const LEVEL_TYPE = { HIGH: 'danger', MID: 'warning', LOW: 'success' }

export function taskType(status) {
  return {
    GENERATED: 'info', READING: 'warning', REVIEWING: 'warning',
    EXCEPTION: 'danger', ARCHIVED: 'success', REJECTED: 'danger',
    MISSED: 'warning', CANCELLED: 'info'
  }[status] || 'info'
}

export function taskLabel(status) {
  return {
    GENERATED: '待执行', READING: '现场抄表', REVIEWING: '待复核', EXCEPTION: '异常处理',
    ARCHIVED: '已归档', REJECTED: '已退回', MISSED: '漏抄', CANCELLED: '已作废'
  }[status] || status
}

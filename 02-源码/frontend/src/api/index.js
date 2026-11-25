import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

// 统一 axios 实例：自动带令牌、统一错误提示、401 回登录页
const http = axios.create({ baseURL: '/api', timeout: 20000 })

http.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('token')
  if (token) cfg.headers.Authorization = 'Bearer ' + token
  return cfg
})

http.interceptors.response.use(
  (res) => {
    const body = res.data
    if (body && body.code !== 200) {
      ElMessage.error(body.message || '请求失败')
      if (body.code === 401) {
        localStorage.removeItem('token')
        router.push('/login')
      }
      return Promise.reject(new Error(body.message))
    }
    return body.data
  },
  (err) => {
    ElMessage.error(err.response?.data?.message || '网络异常，请稍后重试')
    return Promise.reject(err)
  }
)

export default http

export const authApi = {
  login: (data) => http.post('/auth/login', data),
  me: () => http.get('/auth/me'),
  changePassword: (data) => http.post('/auth/password', data),
  updateProfile: (data) => http.put('/auth/profile', data)
}

export const meterApi = {
  page: (params) => http.get('/meter/page', { params }),
  detail: (id) => http.get('/meter/' + id),
  save: (data) => http.post('/meter', data),
  update: (id, data) => http.put('/meter/' + id, data),
  remove: (id) => http.delete('/meter/' + id),
  changeStatus: (id, status) => http.post('/meter/' + id + '/status', null, { params: { status } }),
  buildings: () => http.get('/meter/buildings'),
  units: (buildingId) => http.get('/meter/units', { params: { buildingId } })
}

export const readingApi = {
  taskPage: (params) => http.get('/task/page', { params }),
  generate: (data) => http.post('/task/generate', data),
  assign: (id, readerId) => http.post('/task/' + id + '/assign', null, { params: { readerId } }),
  page: (params) => http.get('/reading/page', { params }),
  submit: (data) => http.post('/reading/submit', data),
  review: (id, data) => http.post('/reading/' + id + '/review', data),
  importExcel: (form) => http.post('/reading/import', form),
  exceptions: (params) => http.get('/exception/page', { params }),
  handleException: (id, data) => http.post('/exception/' + id + '/handle', data)
}

export const billApi = {
  page: (params) => http.get('/bill/page', { params }),
  generate: (period) => http.post('/bill/generate', null, { params: { period } }),
  adjust: (id, data) => http.post('/bill/' + id + '/adjust', data),
  tariffs: () => http.get('/bill/tariffs')
}

export const analysisApi = {
  dashboard: (period) => http.get('/dashboard', { params: { period } }),
  quotaPage: (params) => http.get('/quota/page', { params }),
  saveQuota: (data) => http.post('/quota/save', data),
  measurePage: (params) => http.get('/measure/page', { params }),
  saveMeasure: (data) => http.post('/measure/save', data)
}

export const baselineApi = {
  rule: () => http.get('/baseline/rule'),
  saveRule: (data) => http.post('/baseline/rule', data),
  evaluate: (data) => http.post('/baseline/evaluate', data),
  page: (params) => http.get('/baseline/page', { params }),
  adjust: (id, data) => http.post('/baseline/' + id + '/adjust', data),
  stat: () => http.get('/baseline/stat')
}

export const systemApi = {
  users: (params) => http.get('/system/users', { params }),
  saveUser: (data) => http.post('/system/user', data),
  reset: (id) => http.post('/system/user/' + id + '/reset'),
  roles: () => http.get('/system/roles'),
  orgs: () => http.get('/system/orgs'),
  menus: () => http.get('/system/menus'),
  roleMenus: (roleCode) => http.get('/system/role-menus', { params: { roleCode } }),
  saveRoleMenus: (data) => http.post('/system/role-menus', data),
  messages: () => http.get('/system/messages'),
  readMessage: (id) => http.post('/system/messages/' + id + '/read'),
  logs: (params) => http.get('/system/logs', { params })
}

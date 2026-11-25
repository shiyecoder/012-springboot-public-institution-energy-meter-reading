import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/login', component: () => import('../views/Login.vue'), meta: { public: true } },
  {
    path: '/',
    component: () => import('../layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '节能分析看板' } },
      { path: 'building', component: () => import('../views/Building.vue'), meta: { title: '建筑与用能单元' } },
      { path: 'meter', component: () => import('../views/Meter.vue'), meta: { title: '表计资产台账' } },
      { path: 'task', component: () => import('../views/Task.vue'), meta: { title: '抄表任务' } },
      { path: 'record', component: () => import('../views/Reading.vue'), meta: { title: '抄表记录' } },
      { path: 'exception', component: () => import('../views/Exception.vue'), meta: { title: '异常复核中心' } },
      { path: 'bill', component: () => import('../views/Bill.vue'), meta: { title: '费用台账' } },
      { path: 'quota', component: () => import('../views/Quota.vue'), meta: { title: '能耗定额' } },
      { path: 'baseline', component: () => import('../views/Baseline.vue'), meta: { title: '能耗基线识别' } },
      { path: 'measure', component: () => import('../views/Measure.vue'), meta: { title: '节能措施' } },
      { path: 'system/user', component: () => import('../views/System.vue'), meta: { title: '用户与角色' } },
      { path: 'system/log', component: () => import('../views/Log.vue'), meta: { title: '操作日志' } },
      { path: 'profile', component: () => import('../views/Profile.vue'), meta: { title: '个人资料' } }
    ]
  }
]

const router = createRouter({ history: createWebHistory(), routes })

router.beforeEach((to) => {
  const token = localStorage.getItem('token')
  if (!to.meta.public && !token) return '/login'
  if (to.path === '/login' && token) return '/dashboard'
  return true
})

export default router

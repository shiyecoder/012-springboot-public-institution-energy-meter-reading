<template>
  <div class="layout">
    <aside class="side">
      <div class="brand">
        <div class="logo">能</div>
        <b>能耗监管平台</b>
      </div>
      <div class="dept" v-if="user.orgName">
        <span>{{ user.orgName }}</span>
        <span>{{ scopeText }}</span>
      </div>
      <el-menu
        :default-active="route.path"
        background-color="#0B3A46"
        text-color="#C6DCDE"
        active-text-color="#FFFFFF"
        :collapse="false"
        router
      >
        <template v-for="g in menuTree" :key="g.id">
          <el-sub-menu v-if="g.children.length" :index="String(g.id)">
            <template #title>
              <el-icon><component :is="iconOf(g.icon)" /></el-icon>
              <span>{{ g.menuName }}</span>
            </template>
            <el-menu-item v-for="c in g.children" :key="c.id" :index="c.path">
              {{ c.menuName }}
            </el-menu-item>
          </el-sub-menu>
          <el-menu-item v-else :index="g.path">
            <el-icon><component :is="iconOf(g.icon)" /></el-icon>
            <span>{{ g.menuName }}</span>
          </el-menu-item>
        </template>
      </el-menu>
      <div class="side-foot">市机关事务管理局 · v1.0</div>
    </aside>

    <div class="main">
      <header class="top">
        <div class="crumb">
          <span class="muted">{{ groupName }}</span> / <b>{{ route.meta.title }}</b>
        </div>
        <div class="top-r">
          <span class="scope-badge">{{ scopeText }}</span>
          <el-popover placement="bottom-end" :width="320" trigger="click">
            <template #reference>
              <div class="icon-btn">
                <el-icon><Bell /></el-icon>
                <i v-if="unread" class="dot"></i>
              </div>
            </template>
            <div class="msg-head">站内消息</div>
            <div v-if="!messages.length" class="msg-empty">暂无消息</div>
            <div v-for="m in messages" :key="m.id" class="msg-item" :class="{ read: m.isRead }" @click="readMsg(m)">
              <div class="msg-title">{{ m.title }}</div>
              <div class="msg-content">{{ m.content }}</div>
              <div class="msg-time">{{ formatTime(m.createTime) }}</div>
            </div>
          </el-popover>
          <el-dropdown @command="onCommand">
            <div class="who">
              <img v-if="user.avatar" :src="user.avatar" class="ava" alt="头像" />
              <div v-else class="ava">{{ (user.realName || 'U').slice(0, 1) }}</div>
              <div class="who-txt">
                <div class="nm">{{ user.realName }}</div>
                <div class="rl">{{ roleName }}</div>
              </div>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人资料</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>
      <div class="body">
        <router-view v-slot="{ Component }">
          <component :is="Component" @refresh-user="loadMe" />
        </router-view>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { authApi, systemApi } from '../api'
import { formatTime } from '../utils/format'

const route = useRoute()
const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const menus = ref([])
const messages = ref([])

const ROLE_NAME = { ADMIN: '系统管理员', ENERGY_ADMIN: '能源管理员', READER: '抄表员', LIAISON: '用能部门联络员' }
const roleName = computed(() => ROLE_NAME[user.value.roleCode] || '用户')

const scopeText = computed(() => ({ ALL: '全域数据', DEPT: '本部门数据', SELF: '本人任务' }[user.value.dataScope] || '本人数据'))

const ICONS = {
  dashboard: 'DataBoard', building: 'OfficeBuilding', meter: 'Odometer', task: 'Tickets',
  reading: 'Notebook', warning: 'Warning', bill: 'Money', quota: 'Histogram',
  rule: 'SetUp', leaf: 'Sunny', system: 'Setting', user: 'User', clock: 'Clock'
}
const iconOf = (n) => ICONS[n] || 'Menu'

// 菜单按角色动态获取，前端只做父子分组
const menuTree = computed(() => {
  const roots = menus.value.filter((m) => !m.parentId || m.parentId === 0)
  return roots.map((r) => ({
    ...r,
    children: menus.value.filter((m) => m.parentId === r.id)
  })).filter((g) => g.children.length || g.path)
})

const groupName = computed(() => {
  const g = menuTree.value.find((x) => x.children.some((c) => c.path === route.path))
  return g ? g.menuName : ''
})

async function loadMe() {
  const data = await authApi.me()
  user.value = data.user
  menus.value = data.menus || []
  localStorage.setItem('user', JSON.stringify(data.user))
}

async function loadMessages() {
  try {
    messages.value = await systemApi.messages()
  } catch (e) { /* 消息加载失败不阻塞主流程 */ }
}

const unread = computed(() => messages.value.filter((m) => !m.isRead).length)

async function readMsg(m) {
  if (!m.isRead) {
    await systemApi.readMessage(m.id)
    m.isRead = 1
  }
}

function onCommand(cmd) {
  if (cmd === 'profile') router.push('/profile')
  if (cmd === 'logout') {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    router.push('/login')
  }
}

onMounted(async () => {
  await loadMe()
  loadMessages()
})
</script>

<style scoped>
.layout { display: flex; min-height: 100vh; }
.side {
  width: 220px; flex: 0 0 220px; background: #0B3A46;
  display: flex; flex-direction: column; min-height: 100vh;
}
.brand { height: 56px; display: flex; align-items: center; gap: 9px; padding: 0 18px; border-bottom: 1px solid rgba(255,255,255,.08); }
.brand .logo {
  width: 24px; height: 24px; border-radius: 5px; background: linear-gradient(135deg, #2A7F86, #7FB3B7);
  display: flex; align-items: center; justify-content: center; color: #062B33; font-weight: 600; font-size: 12px;
}
.brand b { color: #fff; font-size: 14px; font-weight: 600; }
.dept {
  margin: 12px 14px 4px; padding: 8px 10px; border-radius: 6px; background: rgba(255,255,255,.06);
  font-size: 12px; color: #A9C6C9; display: flex; justify-content: space-between;
}
.side :deep(.el-menu) { background: transparent; padding: 6px 0; flex: 1; }
.side :deep(.el-menu-item), .side :deep(.el-sub-menu__title) { height: 38px; line-height: 38px; margin: 2px 10px; border-radius: 6px; font-size: 13px; }
.side :deep(.el-menu-item.is-active) { background: #14606F; }
.side :deep(.el-sub-menu .el-menu-item) { min-width: auto; padding-left: 36px !important; }
.side-foot { padding: 12px 18px; border-top: 1px solid rgba(255,255,255,.08); font-size: 11px; color: #6E9196; }
.main { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.top {
  height: 56px; background: #fff; border-bottom: 1px solid var(--c-border);
  display: flex; align-items: center; padding: 0 24px; gap: 16px;
  position: sticky; top: 0; z-index: 20;
}
.crumb { color: var(--c-text-2); font-size: 13px; }
.crumb b { color: var(--c-text); font-weight: 500; }
.top-r { margin-left: auto; display: flex; align-items: center; gap: 14px; }
.scope-badge {
  font-size: 12px; color: var(--c-accent); background: #E7F2F3;
  border: 1px solid #CBE1E3; border-radius: 99px; padding: 3px 10px;
}
.icon-btn { width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: var(--c-text-2); position: relative; cursor: pointer; }
.icon-btn:hover { background: #F0F7F7; }
.icon-btn .dot { position: absolute; top: 6px; right: 6px; width: 7px; height: 7px; background: var(--c-danger); border-radius: 50%; }
.who { display: flex; align-items: center; gap: 8px; padding-left: 12px; border-left: 1px solid var(--c-border); cursor: pointer; }
.ava { width: 29px; height: 29px; border-radius: 50%; background: #D8E9EA; color: #0F4C5C; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; object-fit: cover; }
.nm { font-size: 13px; font-weight: 500; color: var(--c-text); }
.rl { font-size: 11px; color: var(--c-text-2); }
.body { padding: 24px; flex: 1; min-width: 0; }
.msg-head { font-size: 13px; font-weight: 500; margin-bottom: 8px; }
.msg-empty { color: var(--c-text-2); font-size: 12px; padding: 12px 0; }
.msg-item { padding: 8px 0; border-bottom: 1px solid #EDF4F4; cursor: pointer; }
.msg-item.read { opacity: .6; }
.msg-title { font-size: 12.5px; font-weight: 500; }
.msg-content { font-size: 12px; color: var(--c-text-2); margin-top: 2px; }
.msg-time { font-size: 11px; color: #8FA6AB; margin-top: 2px; }

@media (max-width: 900px) {
  .side { display: none; }
  .body { padding: 14px; }
}
</style>

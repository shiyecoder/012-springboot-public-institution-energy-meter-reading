<template>
  <div class="login">
    <div class="left">
      <div class="tag">公共机构能源资源消费统计 · 2026</div>
      <h1>让每一度电<br />都有据可查</h1>
      <p>
        覆盖院区、建筑、用能单元与计量表计的全链路抄表管理，从现场读数到费用台账，
        从异常复核到能耗基线识别，一套系统管到底。
      </p>
      <div class="stats">
        <div><b class="num">1,286</b><span>在线计量表计</span></div>
        <div><b class="num">42</b><span>纳入统计建筑</span></div>
        <div><b class="num">98.6%</b><span>本期抄表完成率</span></div>
      </div>
    </div>
    <div class="right">
      <div class="form">
        <h2>账号登录</h2>
        <div class="hint">请使用单位统一分配的账号，登录后按角色进入对应工作台</div>
        <el-form :model="form" @submit.prevent>
          <el-form-item>
            <el-input v-model="form.username" size="large" placeholder="账号" :prefix-icon="User" />
          </el-form-item>
          <el-form-item>
            <el-input v-model="form.password" size="large" type="password" show-password
                      placeholder="密码" :prefix-icon="Lock" @keyup.enter="doLogin" />
          </el-form-item>
          <el-button type="primary" size="large" class="submit" :loading="loading" @click="doLogin">
            登 录
          </el-button>
        </el-form>
        <div class="roles">
          <div v-for="r in roleHints" :key="r.code" class="role" :class="{ on: form.username === r.user }"
               @click="fill(r)">{{ r.name }}</div>
        </div>
        <div class="foot">连续 5 次密码错误将锁定账号 10 分钟</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { authApi } from '../api'

const router = useRouter()
const loading = ref(false)
const form = reactive({ username: 'admin', password: 'admin123' })

const roleHints = [
  { code: 'ADMIN', name: '系统管理员', user: 'admin', pwd: 'admin123' },
  { code: 'ENERGY_ADMIN', name: '能源管理员', user: 'zhangli', pwd: '123456' },
  { code: 'READER', name: '抄表员', user: 'wangjg', pwd: '123456' },
  { code: 'LIAISON', name: '部门联络员', user: 'cheny', pwd: '123456' }
]

function fill(r) {
  form.username = r.user
  form.password = r.pwd
}

async function doLogin() {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入账号和密码')
    return
  }
  loading.value = true
  try {
    const data = await authApi.login(form)
    localStorage.setItem('token', data.token)
    localStorage.setItem('user', JSON.stringify(data.user))
    ElMessage.success('登录成功')
    router.push('/dashboard')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login { display: flex; min-height: 100vh; }
.left {
  width: 54%; padding: 56px 60px; color: #fff; position: relative; overflow: hidden;
  display: flex; flex-direction: column;
  /* 真实本地背景图（uploads/seed/bg/login.jpg）+ 左侧渐变压暗，保证白色文案可读 */
  background:
    linear-gradient(102deg, rgba(7,40,50,.95) 0%, rgba(11,58,70,.88) 38%, rgba(15,76,92,.55) 74%, rgba(15,76,92,.30) 100%),
    url('/uploads/seed/bg/login.jpg') center/cover no-repeat,
    linear-gradient(150deg, #0B3A46 0%, #0F4C5C 60%, #1C6572 100%);
}
/* 底部压暗层：让指标区落在深色底上，不依赖运气 */
.left:before {
  content: ''; position: absolute; left: 0; right: 0; bottom: 0; height: 46%;
  background: linear-gradient(to top, rgba(4,28,36,.86) 0%, rgba(4,28,36,.55) 45%, rgba(4,28,36,0) 100%);
  pointer-events: none;
}
.tag {
  display: inline-flex; align-items: center; gap: 8px; align-self: flex-start; position: relative;
  background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.22); backdrop-filter: blur(4px);
  border-radius: 99px; padding: 5px 12px; font-size: 12px; color: #E3F1F2;
}
.left h1 { font-size: 34px; font-weight: 600; line-height: 1.42; margin: auto 0 0; letter-spacing: .5px; position: relative; text-shadow: 0 1px 8px rgba(2,22,28,.55); }
.left p { color: #C3DBDE; margin-top: 14px; font-size: 13.5px; max-width: 440px; line-height: 1.95; position: relative; text-shadow: 0 1px 6px rgba(2,22,28,.5); }
.stats { display: flex; gap: 36px; margin-top: 34px; padding-top: 22px; border-top: 1px solid rgba(255,255,255,.18); position: relative; }
.stats b { display: block; font-size: 22px; font-weight: 600; }
.stats span { font-size: 11.5px; color: #9FBDC1; }
.right { flex: 1; display: flex; align-items: center; justify-content: center; background: #fff; }
.form { width: 360px; }
.form h2 { font-size: 22px; font-weight: 600; margin: 0; }
.hint { color: var(--c-text-2); font-size: 12.5px; margin: 8px 0 26px; line-height: 1.7; }
.submit { width: 100%; height: 42px; margin-top: 4px; font-size: 14px; }
.roles { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 18px; }
.role {
  border: 1px solid var(--c-border); border-radius: 6px; padding: 8px 10px;
  font-size: 12px; color: var(--c-text-2); cursor: pointer; text-align: center;
}
.role:hover { border-color: #9FC4C7; }
.role.on { border-color: var(--c-secondary); background: #EAF3F3; color: var(--c-primary); font-weight: 500; }
.foot { color: #9AAFB4; font-size: 11.5px; text-align: center; margin-top: 18px; }
@media (max-width: 900px) {
  .left { display: none; }
}
</style>

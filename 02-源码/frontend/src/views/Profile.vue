<template>
  <div>
    <div class="page-title">个人资料</div>
    <div class="page-sub" style="margin-bottom: 14px">头像上传后右上角同步显示；密码使用 BCrypt 保存，接口不返回密码字段</div>
    <div class="grid">
      <div class="card">
        <div class="card-title">基本信息</div>
        <el-form :model="form" label-width="100px">
          <el-form-item label="头像">
            <Uploader v-model="form.avatar" hint="建议 1:1 正方形，≤5MB" />
          </el-form-item>
          <el-form-item label="账号"><el-input v-model="form.username" disabled /></el-form-item>
          <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
          <el-form-item label="手机"><el-input v-model="form.phone" /></el-form-item>
          <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
          <el-form-item label="角色">
            <el-input :model-value="ROLE[form.roleCode]" disabled />
          </el-form-item>
        </el-form>
        <div class="btns"><el-button type="primary" @click="saveProfile">保存资料</el-button></div>
      </div>
      <div class="card">
        <div class="card-title">修改密码</div>
        <el-form :model="pwd" label-width="90px">
          <el-form-item label="原密码"><el-input v-model="pwd.oldPassword" type="password" show-password /></el-form-item>
          <el-form-item label="新密码"><el-input v-model="pwd.newPassword" type="password" show-password placeholder="不少于 6 位" /></el-form-item>
          <el-form-item label="确认密码"><el-input v-model="pwd.confirm" type="password" show-password /></el-form-item>
        </el-form>
        <div class="btns"><el-button type="primary" @click="savePwd">修改密码</el-button></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import Uploader from '../components/Uploader.vue'
import { authApi } from '../api'

const emit = defineEmits(['refresh-user'])
const ROLE = { ADMIN: '系统管理员', ENERGY_ADMIN: '能源管理员', READER: '抄表员', LIAISON: '用能部门联络员' }
const form = reactive({ username: '', realName: '', phone: '', email: '', avatar: '', roleCode: '' })
const pwd = reactive({ oldPassword: '', newPassword: '', confirm: '' })

async function load() {
  const d = await authApi.me()
  Object.assign(form, d.user)
}

async function saveProfile() {
  await authApi.updateProfile({ realName: form.realName, phone: form.phone, email: form.email, avatar: form.avatar })
  ElMessage.success('资料已更新')
  const d = await authApi.me()
  localStorage.setItem('user', JSON.stringify(d.user))
  emit('refresh-user')
}

async function savePwd() {
  if (pwd.newPassword.length < 6) { ElMessage.warning('新密码不少于 6 位'); return }
  if (pwd.newPassword !== pwd.confirm) { ElMessage.warning('两次输入不一致'); return }
  await authApi.changePassword({ oldPassword: pwd.oldPassword, newPassword: pwd.newPassword })
  ElMessage.success('密码已修改')
  pwd.oldPassword = pwd.newPassword = pwd.confirm = ''
}

onMounted(load)
</script>

<style scoped>
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; align-items: start; }
.btns { display: flex; justify-content: flex-end; }
</style>

<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">用户与角色</div>
        <div class="page-sub">4 个角色 · 菜单权限按角色动态下发，未授权菜单不出现在侧边栏</div>
      </div>
      <el-button type="primary" @click="open()">新增用户</el-button>
    </div>
    <div class="grid">
      <div class="card" style="padding: 0">
        <el-table :data="rows" v-loading="loading">
          <el-table-column prop="username" label="账号" min-width="120" />
          <el-table-column prop="realName" label="姓名" min-width="100" />
          <el-table-column label="角色" min-width="130">
            <template #default="{ row }">{{ ROLE[row.roleCode] || row.roleCode }}</template>
          </el-table-column>
          <el-table-column prop="orgName" label="所属组织" min-width="170" />
          <el-table-column prop="dataScope" label="数据范围" min-width="100">
            <template #default="{ row }">{{ SCOPE[row.dataScope] }}</template>
          </el-table-column>
          <el-table-column label="状态" min-width="90">
            <template #default="{ row }">
              <el-tag :type="row.status === '启用' ? 'success' : 'info'" effect="light">{{ row.status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" min-width="160">
            <template #default="{ row }">
              <el-button link type="primary" @click="open(row)">编辑</el-button>
              <el-button link type="primary" @click="reset(row)">重置密码</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="pager">
          <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                         :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
        </div>
      </div>
      <div class="card">
        <div class="card-title">为角色分配菜单</div>
        <el-select v-model="roleCode" style="width: 100%; margin-bottom: 12px" @change="loadRoleMenus">
          <el-option v-for="r in roles" :key="r.roleCode" :label="r.roleName" :value="r.roleCode" />
        </el-select>
        <el-checkbox-group v-model="menuIds" class="menus">
          <el-checkbox v-for="m in menus" :key="m.id" :label="m.id" :disabled="m.menuName === '菜单管理'">
            {{ m.menuName }}
          </el-checkbox>
        </el-checkbox-group>
        <div class="row-btns">
          <el-button @click="loadRoleMenus">重置</el-button>
          <el-button type="primary" @click="saveRoleMenus">保存授权</el-button>
        </div>
      </div>
    </div>

    <el-dialog v-model="visible" :title="form.id ? '编辑用户' : '新增用户'" width="480px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="账号" required><el-input v-model="form.username" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.roleCode" style="width: 200px">
            <el-option v-for="r in roles" :key="r.roleCode" :label="r.roleName" :value="r.roleCode" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属组织">
          <el-select v-model="form.orgId" style="width: 220px">
            <el-option v-for="o in orgs" :key="o.id" :label="o.orgName" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="手机"><el-input v-model="form.phone" /></el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio label="启用" /><el-radio label="停用" />
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="!form.id" label="初始密码">
          <el-input v-model="form.password" placeholder="默认 123456" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="visible = false">取消</el-button>
        <el-button type="primary" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { systemApi } from '../api'

const ROLE = { ADMIN: '系统管理员', ENERGY_ADMIN: '能源管理员', READER: '抄表员', LIAISON: '用能部门联络员' }
const SCOPE = { ALL: '全域', DEPT: '本部门', SELF: '本人' }
const rows = ref([])
const roles = ref([])
const orgs = ref([])
const menus = ref([])
const menuIds = ref([])
const roleCode = ref('ENERGY_ADMIN')
const total = ref(0)
const loading = ref(false)
const visible = ref(false)
const q = reactive({ page: 1, size: 10 })
const form = reactive({ id: null, username: '', realName: '', roleCode: 'READER', orgId: null, phone: '', status: '启用', password: '' })

async function load() {
  loading.value = true
  try {
    const d = await systemApi.users(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

async function loadRoleMenus() {
  menuIds.value = await systemApi.roleMenus(roleCode.value)
}

function open(row) {
  if (row) Object.assign(form, row)
  else Object.assign(form, { id: null, username: '', realName: '', roleCode: 'READER', orgId: null, phone: '', status: '启用', password: '' })
  visible.value = true
}

async function save() {
  if (!form.username) { ElMessage.warning('账号必填'); return }
  await systemApi.saveUser(form)
  ElMessage.success('保存成功')
  visible.value = false
  load()
}

async function reset(row) {
  await ElMessageBox.confirm(`确认将 ${row.realName} 的密码重置为 123456？`, '重置确认', { type: 'warning' })
  await systemApi.reset(row.id)
  ElMessage.success('已重置')
}

async function saveRoleMenus() {
  await systemApi.saveRoleMenus({ roleCode: roleCode.value, menuIds: menuIds.value })
  ElMessage.success('授权已保存，该角色重新登录后生效')
}

onMounted(async () => {
  roles.value = await systemApi.roles()
  orgs.value = await systemApi.orgs()
  menus.value = await systemApi.menus()
  load()
  loadRoleMenus()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.grid { display: grid; grid-template-columns: 1fr 320px; gap: 12px; align-items: start; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
.menus { display: flex; flex-direction: column; gap: 2px; max-height: 420px; overflow: auto; }
.row-btns { display: flex; justify-content: flex-end; gap: 8px; margin-top: 12px; }
</style>

<template>
  <div>
    <div class="page-title">操作日志</div>
    <div class="page-sub" style="margin-bottom: 14px">记录所有写操作，包含操作人、请求路径、耗时与结果</div>
    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading" size="small">
        <el-table-column prop="username" label="操作人" min-width="110" />
        <el-table-column prop="module" label="模块" min-width="120" />
        <el-table-column prop="action" label="动作" min-width="120" />
        <el-table-column prop="method" label="请求" min-width="280" show-overflow-tooltip />
        <el-table-column prop="ip" label="IP" min-width="130" />
        <el-table-column prop="costMs" label="耗时(ms)" min-width="100" align="right" />
        <el-table-column label="结果" min-width="90">
          <template #default="{ row }">
            <el-tag :type="row.result === 'OK' ? 'success' : 'danger'" effect="light">{{ row.result }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="时间" min-width="160">
          <template #default="{ row }">{{ formatTime(row.createTime) }}</template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="q.size"
                       :current-page="q.page" @current-change="(p) => { q.page = p; load() }" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { systemApi } from '../api'
import { formatTime } from '../utils/format'

const rows = ref([])
const total = ref(0)
const loading = ref(false)
const q = reactive({ page: 1, size: 10 })

async function load() {
  loading.value = true
  try {
    const d = await systemApi.logs(q)
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}
onMounted(load)
</script>

<style scoped>
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
</style>

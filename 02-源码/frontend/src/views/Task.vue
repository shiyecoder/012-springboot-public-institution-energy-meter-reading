<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">抄表任务</div>
        <div class="page-sub">{{ q.period }} 批次 · 共 {{ total }} 项 · 待执行与待复核优先展示</div>
      </div>
      <div class="ops">
        <el-button @click="genVisible = true">生成月度计划</el-button>
        <el-button type="primary" :icon="Upload" @click="importVisible = true">Excel 导入</el-button>
      </div>
    </div>

    <div class="filter-bar">
      <el-select v-model="q.period" style="width: 180px" @change="reload">
        <el-option v-for="p in periods" :key="p" :label="p" :value="p" />
      </el-select>
      <el-tag v-for="t in tabs" :key="t.value" :type="q.status === t.value ? 'primary' : 'info'"
              :effect="q.status === t.value ? 'dark' : 'plain'" class="tab"
              @click="q.status = q.status === t.value ? null : t.value; reload()">
        {{ t.label }}
      </el-tag>
      <el-select v-model="q.buildingId" placeholder="全部建筑" clearable style="width: 200px" @change="reload">
        <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
      </el-select>
    </div>

    <div class="card" style="padding: 0">
      <el-table :data="rows" v-loading="loading" class="pc-table">
        <el-table-column prop="taskNo" label="任务编号" min-width="160">
          <template #default="{ row }"><span class="num">{{ row.taskNo }}</span></template>
        </el-table-column>
        <el-table-column prop="buildingName" label="抄表范围" min-width="170" />
        <el-table-column prop="meterCode" label="表计编号" min-width="130">
          <template #default="{ row }"><span class="num">{{ row.meterCode }}</span></template>
        </el-table-column>
        <el-table-column prop="installLocation" label="安装位置" min-width="160" />
        <el-table-column prop="readerName" label="抄表员" min-width="90" />
        <el-table-column prop="deadline" label="截止日期" min-width="110" />
        <el-table-column label="状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="taskType(row.status)" effect="light">{{ row.statusLabel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="160" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :disabled="!['GENERATED','READING','REJECTED'].includes(row.status)"
                       @click="openSubmit(row)">执行抄表</el-button>
            <el-button link type="primary" @click="$router.push('/record')">查看记录</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 移动端（<768px）表格转信息卡片：只留编号、状态、时间、负责人，点击进详情（需求"移动端适配"） -->
      <div class="m-cards">
        <div v-for="row in rows" :key="row.id" class="m-card" @click="openSubmit(row)">
          <div class="m-top">
            <span class="m-no num">{{ row.taskNo }}</span>
            <el-tag :type="taskType(row.status)" effect="light" size="small">{{ row.statusLabel }}</el-tag>
          </div>
          <div class="m-mid">{{ row.buildingName }} · {{ row.installLocation }}</div>
          <div class="m-foot">
            <span>{{ row.readerName || '未派单' }}</span>
            <span class="num">截止 {{ row.deadline }}</span>
          </div>
        </div>
        <div v-if="!rows.length" class="m-empty">当前筛选条件下无任务，可切换批次或清空筛选</div>
      </div>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
                       :page-size="q.size" :current-page="q.page" :page-sizes="[10, 20, 50]"
                       @current-change="(p) => { q.page = p; load() }"
                       @size-change="(s) => { q.size = s; q.page = 1; load() }" />
      </div>
    </div>

    <el-dialog v-model="genVisible" title="生成月度抄表计划" width="460px">
      <el-form label-width="90px">
        <el-form-item label="周期"><el-input v-model="gen.period" placeholder="yyyy-MM" /></el-form-item>
        <el-form-item label="建筑">
          <el-select v-model="gen.buildingId" clearable placeholder="全部建筑" style="width: 240px">
            <el-option v-for="b in buildings" :key="b.id" :label="b.buildingName" :value="b.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <div class="tip">同一表计同一周期不会重复生成任务；已归档任务不受影响。</div>
      <template #footer>
        <el-button @click="genVisible = false">取消</el-button>
        <el-button type="primary" @click="doGenerate">生成</el-button>
      </template>
    </el-dialog>

    <el-drawer v-model="submitVisible" title="现场抄表录入" size="520px">
      <el-descriptions :column="2" border size="small" style="margin-bottom: 16px">
        <el-descriptions-item label="任务编号">{{ current.taskNo }}</el-descriptions-item>
        <el-descriptions-item label="表计">{{ current.meterCode }}</el-descriptions-item>
        <el-descriptions-item label="安装位置">{{ current.installLocation }}</el-descriptions-item>
        <el-descriptions-item label="上期读数">{{ num(current.lastReading) }}</el-descriptions-item>
      </el-descriptions>
      <el-form :model="reading" label-width="100px">
        <el-form-item label="本期读数" required>
          <el-input v-model="reading.currReading" placeholder="按表盘实际读数填写" />
        </el-form-item>
        <el-form-item label="表计状态">
          <el-select v-model="reading.meterStatus" style="width: 200px">
            <el-option label="正常" value="正常" /><el-option label="异常" value="异常" />
            <el-option label="损坏" value="损坏" />
          </el-select>
        </el-form-item>
        <el-form-item label="抄表时间">
          <el-date-picker v-model="reading.readTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss"
                          style="width: 260px" />
        </el-form-item>
        <el-form-item label="表盘照片" required>
          <Uploader v-model="reading.photoPath" hint="现场拍摄表盘，需能辨识读数" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="reading.remark" type="textarea" :rows="2" maxlength="100" show-word-limit />
        </el-form-item>
      </el-form>
      <div v-if="preview" class="preview">本期用量 <b class="num">{{ preview.usage }}</b>，
        与历史均值偏差 <b class="num">{{ preview.deviation }}%</b>
        <span v-if="preview.exceptionNo" class="warn">　已自动生成异常单 {{ preview.exceptionNo }}</span>
      </div>
      <template #footer>
        <el-button @click="submitVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doSubmit">提交复核</el-button>
      </template>
    </el-drawer>

    <el-dialog v-model="importVisible" title="Excel 批量导入抄表数据" width="520px">
      <div class="tip">模板列：表计编号 | 本期读数 | 抄表时间 | 备注。导入失败会返回行号与原因。</div>
      <el-upload :auto-upload="false" :limit="1" :on-change="onFile" accept=".xlsx">
        <el-button :icon="Upload">选择 Excel 文件</el-button>
      </el-upload>
      <div v-if="importResult.errors && importResult.errors.length" class="errors">
        <div v-for="e in importResult.errors" :key="e.row">第 {{ e.row }} 行：{{ e.reason }}</div>
      </div>
      <div v-if="importResult.success !== undefined" class="tip">
        成功 {{ importResult.success }} 行，失败 {{ importResult.failed }} 行
      </div>
      <template #footer>
        <el-button @click="importVisible = false">关闭</el-button>
        <el-button type="primary" :disabled="!file" @click="doImport">开始导入</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload } from '@element-plus/icons-vue'
import Uploader from '../components/Uploader.vue'
import { meterApi, readingApi } from '../api'
import { num, taskType } from '../utils/format'

const rows = ref([])
const buildings = ref([])
const total = ref(0)
const loading = ref(false)
const saving = ref(false)
const genVisible = ref(false)
const submitVisible = ref(false)
const importVisible = ref(false)
const current = ref({})
const preview = ref(null)
const file = ref(null)
const importResult = ref({})

const periods = ['2026-10', '2026-09', '2026-08', '2026-07', '2026-06', '2026-05']
const tabs = [
  { label: '全部', value: null }, { label: '待执行', value: 'GENERATED' },
  { label: '待复核', value: 'REVIEWING' }, { label: '异常', value: 'EXCEPTION' },
  { label: '已归档', value: 'ARCHIVED' }
]

const q = reactive({ page: 1, size: 10, period: '2026-10', status: null, buildingId: null })
const gen = reactive({ period: '2026-10', buildingId: null })
const reading = reactive({ taskId: null, currReading: '', meterStatus: '正常', readTime: '', photoPath: '', remark: '' })

async function load() {
  loading.value = true
  try {
    const d = await readingApi.taskPage({ ...q })
    rows.value = d.records
    total.value = d.total
  } finally {
    loading.value = false
  }
}

function reload() { q.page = 1; load() }

function openSubmit(row) {
  current.value = row
  Object.assign(reading, { taskId: row.id, currReading: '', meterStatus: '正常', readTime: '', photoPath: '', remark: '' })
  preview.value = null
  submitVisible.value = true
}

async function doSubmit() {
  if (!reading.currReading) { ElMessage.warning('请填写本期读数'); return }
  if (!reading.photoPath) { ElMessage.warning('请上传表盘照片'); return }
  saving.value = true
  try {
    const d = await readingApi.submit(reading)
    preview.value = d
    ElMessage.success('已提交，等待复核')
    submitVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function doGenerate() {
  const n = await readingApi.generate(gen)
  ElMessage.success(`已生成 ${n} 条抄表任务`)
  genVisible.value = false
  reload()
}

function onFile(f) { file.value = f.raw }
async function doImport() {
  const form = new FormData()
  form.append('file', file.value)
  form.append('period', q.period)
  importResult.value = await readingApi.importExcel(form)
  ElMessage.success('导入完成')
  load()
}

onMounted(async () => {
  buildings.value = await meterApi.buildings()
  load()
})
</script>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
.ops { display: flex; gap: 10px; }
.pager { display: flex; justify-content: flex-end; padding: 12px 14px; }
.tab { cursor: pointer; }
.tip { font-size: 12px; color: var(--c-text-2); line-height: 1.8; margin: 6px 0; }
.preview { background: #EAF3F3; border: 1px solid #CBE1E3; border-radius: 6px; padding: 10px 12px; font-size: 12.5px; color: #16323A; }
.preview .warn { color: #B02A37; }
.errors { max-height: 160px; overflow: auto; font-size: 12px; color: #B02A37; background: #FBEAEC; padding: 8px 10px; border-radius: 6px; }

/* 移动端卡片列表：桌面端隐藏 */
.m-cards { display: none; }

@media (max-width: 768px) {
  .pc-table { display: none; }
  .m-cards { display: block; padding: 8px 0; }
  .m-card { padding: 12px 14px; border-bottom: 1px solid #EDF4F4; cursor: pointer; }
  .m-card:active { background: #F3F8F8; }
  .m-top { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
  .m-no { font-size: 13px; font-weight: 600; color: var(--c-primary); }
  .m-mid { font-size: 12.5px; color: #3C565C; margin-top: 6px; line-height: 1.6; }
  .m-foot { display: flex; justify-content: space-between; font-size: 11.5px; color: var(--c-text-2); margin-top: 6px; }
  .m-empty { padding: 28px 14px; text-align: center; font-size: 12.5px; color: var(--c-text-2); }
  .head { flex-direction: column; gap: 10px; }
  .filter-bar { flex-wrap: wrap; }
}
</style>

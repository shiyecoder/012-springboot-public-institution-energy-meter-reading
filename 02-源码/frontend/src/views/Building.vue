<template>
  <div>
    <div class="page-title">建筑与用能单元</div>
    <div class="page-sub" style="margin-bottom: 14px">维护院区、建筑、楼层与用能单元的级联关系，表计挂接到用能单元</div>
    <div class="cards">
      <div v-for="b in buildings" :key="b.id" class="bcard" @click="select(b)">
        <img :src="b.coverImage" :alt="b.buildingName" class="cover" />
        <div class="binfo">
          <div class="bname">{{ b.buildingName }}</div>
          <div class="bmeta">{{ TYPE[b.buildingType] }} · {{ b.floorCount }} 层 · {{ num(b.buildArea, 0) }} ㎡</div>
          <div class="bmeta">{{ b.address }}</div>
          <div class="bstats">
            <span>使用人数 <b class="num">{{ b.personCount }}</b></span>
            <span>责任人 {{ b.manager }}</span>
          </div>
        </div>
      </div>
    </div>
    <div class="card" style="margin-top: 14px">
      <div class="card-title">
        <span>{{ current?.buildingName || '选择建筑查看用能单元' }} · 用能单元</span>
      </div>
      <el-table :data="units" size="small">
        <el-table-column prop="unitCode" label="单元编码" min-width="110" />
        <el-table-column prop="unitName" label="单元名称" min-width="160" />
        <el-table-column prop="floorNo" label="楼层" min-width="100" />
        <el-table-column prop="roomRange" label="房间范围" min-width="140" />
        <el-table-column prop="area" label="面积㎡" min-width="100" align="right">
          <template #default="{ row }"><span class="num">{{ num(row.area, 0) }}</span></template>
        </el-table-column>
        <el-table-column prop="personCount" label="人数" min-width="90" align="right" />
        <el-table-column prop="status" label="状态" min-width="90" />
      </el-table>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { meterApi } from '../api'
import { num } from '../utils/format'

const TYPE = { SCHOOL: '学校', HOSPITAL: '医院', OFFICE: '办公', CULTURE: '文化' }
const buildings = ref([])
const units = ref([])
const current = ref(null)

async function select(b) {
  current.value = b
  units.value = await meterApi.units(b.id)
}

onMounted(async () => {
  buildings.value = await meterApi.buildings()
  if (buildings.value.length) select(buildings.value[0])
})
</script>

<style scoped>
.cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.bcard { background: #fff; border: 1px solid var(--c-border); border-radius: 8px; overflow: hidden; cursor: pointer; }
.bcard:hover { border-color: #9FC4C7; }
.cover { width: 100%; height: 104px; object-fit: cover; display: block; background: #E8F1F3; }
.binfo { padding: 10px 12px; }
.bname { font-size: 14px; font-weight: 500; }
.bmeta { font-size: 11.5px; color: var(--c-text-2); margin-top: 2px; }
.bstats { display: flex; justify-content: space-between; font-size: 11.5px; color: var(--c-text-2); margin-top: 6px; border-top: 1px solid #EDF4F4; padding-top: 6px; }
.bstats b { color: var(--c-primary); }
@media (max-width: 1400px) { .cards { grid-template-columns: repeat(3, 1fr); } }
</style>

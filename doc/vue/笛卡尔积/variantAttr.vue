<template>
  <el-form ref="form" :model="form" size="mini" :label-width="labelWidth" class="w-90 form-col" :rules="rules">
    <el-row>
      <el-col :span="24">
        <el-form-item label="颜色">
<!--          <el-checkbox-group v-model="form.color" @change="changeColor">
            <el-checkbox v-for="item in colorItem" :key="item.label" :label="item.label">
              <div v-if="item.color" :style="{background:item.color}" class="color" />{{ item.label }}</el-checkbox>
          </el-checkbox-group>-->
<!--          TODO mjf-->
          <el-checkbox-group v-model="form.color" @change="colorChange">
            <el-checkbox v-for="item in colorItem" :key="item.label" :label="item.label">
              <div v-if="item.color" :style="{background:item.color}" class="color" />{{ item.label }}</el-checkbox>
          </el-checkbox-group>
          <span>添加其他颜色</span>
          <el-input v-model="colorVal" placeholder="请输入颜色值" style="width:200px;" class="mx-2" />
          <el-button @click="addColorVal">添加</el-button>
          <span class="mx-2" style="color:red">说明：请首先按要求添加！双色支持格式：黑白；单色请参考：<g-link>
            <span class="herfColor" @click="handleColorCell">wish官方颜色列表>></span>
          </g-link>
          </span>
        </el-form-item>
      </el-col>
      <el-col :span="24">
        <el-form-item label="尺码" prop="size">
          <ul class="sizeList">
            <li v-for="(item,index) in sizeOption" :key="`${item.label}+${item.index}`" :class="tableTemp === index+1?'active':''">
              <span @click="changeSize(item)">{{ item.label }}</span>
            </li>
          </ul>
          <div id="item_category" :style="showSize?'border: 1px solid #c5d0dc':''" class="me-5">
            <!-- <span v-if="[1,2,8,9,25].includes(tableTemp)" style="margin-left:10px;line-height:50px;">{{ tableTitle }}</span> -->
            <template v-if="[1,2,25].includes(tableTemp)">
              <el-table :data="menApparelTable" class="g-table">
                <el-table-column>
                  <template slot-scope="{row}">
                   <!-- <el-checkbox v-model="row.checked" @change="changeMenApparelSize(row)" />-->
                    <!--// TODO mjf-->
                    <el-checkbox v-model="row.checked" @change="sizeChange(row)" />
                    {{ row.size }}
                  </template>
                </el-table-column>
                <el-table-column label="Chest">
                  <el-table-column prop="ChestCm" label="厘米" />
                  <el-table-column prop="ChestInch" label="英寸" width="90" />
                </el-table-column>
                <el-table-column :label="tableTemp=== 25?'高度':'Waist'">
                  <el-table-column prop="WaistCm" label="厘米" />
                  <el-table-column prop="WaistInch" label="英寸" width="90" />
                </el-table-column>
                <template v-if="tableTemp === 1">
                  <el-table-column label="Neck">
                    <el-table-column prop="NeckCm" label="厘米" />
                    <el-table-column prop="NeckInch" label="英寸" width="80" />
                  </el-table-column>
                  <el-table-column label="Sleeve">
                    <el-table-column prop="SleeveCm" label="厘米" />
                    <el-table-column prop="SleeveInch" label="英寸" width="80" />
                  </el-table-column>
                </template>
                <el-table-column v-if="tableTemp ===2" label="Hip">
                  <el-table-column prop="hipCm" label="厘米" />
                  <el-table-column prop="hipInch" label="英寸" width="90" />
                </el-table-column>
              </el-table>
            </template>
            <template v-if="showSize">
              <p v-if="[17,18,19,20,21,22].includes(tableTemp)">Example: {{ filterDesc }}</p>
              <p v-if="[26].includes(tableTemp)">Example: Hardcover, Cookies & Cream, 12-Pack (max 50 characters)</p>
              <el-checkbox-group v-model="childShoesList" @change="changeMenApparelSize(childShoesList)">
                <el-checkbox v-for="(v,key) in menApparelTable" :key="key" :label="v">{{ v }}</el-checkbox>
              </el-checkbox-group>
              <template v-if="[17,18,19,20,21,22,26].includes(tableTemp)">
                <div class="d-flex">
                  <el-input v-model="areaSize" class="w-20 me-2" />
                  <el-button @click="addArea(areaSize)">添加</el-button>
                </div>
              </template>
              {{ childShoesList }}
            </template>
            <template v-if="[8,9].includes(tableTemp)">
              <el-table :data="menApparelTable" class="g-table">
                <el-table-column>
                  <el-table-column label="美国标准尺码" width="120">
                    <template slot-scope="{row}">
                      <el-checkbox v-model="row.checked" @change="changeMenApparelSize(row)" />
                      {{ row.size }}
                    </template>
                  </el-table-column>
                  <el-table-column prop="european" label="European" />
                </el-table-column>
                <el-table-column label="脚长">
                  <el-table-column prop="ch" label="英寸" />
                  <el-table-column prop="cm" label="厘米" />
                </el-table-column>
              </el-table>
            </template>
          </div>
        </el-form-item>
      </el-col>
      <!-- v-show="sizeList.length" -->
      <el-col :span="24">
        <div>
          <el-table :data="form.variantList" border class="g-table" :row-key="getRowKeys">
            <el-table-column label="颜色" prop="color" />
            <el-table-column label="尺码" prop="size" />
            <el-table-column label="售价">
              <template slot="header"><span class="has-error">售价</span></template>
              <template slot-scope="{row,$index}">
                <el-form-item :prop="'variantList.' + $index + '.localizedPrice'"
                              :rules="[{ required: true, message: '售价不能为空', trigger: 'blur' }]"
                              class="el-form-item_no-lable mb-0"
                >
                  <el-input v-model="row.localizedPrice" placeholder="请输入" @blur="handleLocalizedPrice(row,$index)" />
                </el-form-item>
              </template>
            </el-table-column>
            <el-table-column label="成本" prop="costPrice" />
            <!-- <el-table-column label="成本">
              <template v-slot="{row,$index}">
                <el-form-item :prop="'variantList.' + $index + '.costPrice'"
                              :rules="[{required:true,validator:validateCostPrice(row,$index),trigger:'blur'}]"
                              class="el-form-item_no-lable mb-0"
                >
                  <el-input v-model="row.costPrice" size="mini" placeholder="请输入" />
                </el-form-item>
              </template>
            </el-table-column> -->
            <el-table-column label="利润率">
              <template slot-scope="{row,$index}">
                <el-form-item :prop="'variantList.' + $index + '.profitRate'"
                              :rules="[{ required: true, validator: validateProfitRate(row,$index), trigger: 'blur'}]"
                              class="el-form-item_no-lable mb-0"
                >
                  <el-input v-model="row.profitRate" maxlength="4" size="mini" placeholder="请输入" @blur="changeProfitRate(row,$index)" />
                </el-form-item>
              </template>
            </el-table-column>
            <el-table-column label="库存">
              <template slot="header"><span class="has-error">库存</span></template>
              <template slot-scope="{row,$index}">
                <el-form-item :prop="'variantList.' + $index + '.inventory'"
                              :rules="[{ required: true, message: '库存不能为空', trigger: 'blur' }]"
                              class="el-form-item_no-lable mb-0"
                >
                  <el-input v-model="row.inventory" placeholder="请输入" />
                </el-form-item>
              </template>
            </el-table-column>
            <el-table-column label="商品编码">
              <template slot="header"><span class="has-error">商品编码</span></template>
              <template slot-scope="{row,$index}">
                <el-form-item :prop="'variantList.' + $index + '.productSku'"
                              :rules="[{ required: true, message: '商品编码不能为空', trigger: 'blur' }]"
                              class="el-form-item_no-lable mb-0"
                >
                  <el-select v-model="row.productSku" @change="(value) => changeProductSku(value,row,$index)">
                    <el-option v-for="item in totalSku" :key="item.productSku" :label="item.productSku" :value="item.productSku" />
                  </el-select>
                </el-form-item>
              </template>
            </el-table-column>
            <el-table-column v-if="itemId" label="是否上架">
              <template slot-scope="{row}">
                <el-switch v-model="row.isEnabled" class="ms-2" />
              </template>
            </el-table-column>
            <el-table-column label="操作">
              <template slot-scope="{row,$index}">
                <el-button icon="el-icon-plus" circle @click="handlerAdd(row,$index)" />
                <!-- v-if="!itemId" -->
                <template>
                  <el-button icon="el-icon-minus" circle @click="handlerDel(row,$index)" />
                </template>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-col>
    </el-row>
  </el-form>
</template>

<script>
import { deepClone } from '@/util/util'
import * as addListingHandle from './addListing.handle.js'
import { calculatePrice, calculateProfitRate } from '@/api/wish/wish.js'
import {
  getSpuDetailByProduct
} from '@/api/amazon/amazon.js'
const descTitle = ['1.4m x 1.4m, 10.5" * 10.5", 10cm by 10cm by 10cm',
  '6\' 5", 10m, 5", 11.5cm, 6ft 5in',
  '100mL, 200L, 40 fl. oz., 10.5pt',
  ' 100V, 50v',
  '10W, 30W, 100W',
  '100kg, 11.5lb, 3.14g']
const variantList = () => [{
  productSku: '', // 子sku
  color: '', // 颜色
  size: '', // 尺码
  msrp: '', // 参考价格
  price: null, // 价格 后端会给
  localizedPrice: null, // 本地价格
  localizedShipping: null, // 本地运费
  costPrice: null, // 成本
  shipping: null, // 运费
  inventory: null, // 库存
  shippingTime: null, // 运费时长
  profitRate: null // 利润率
}] // 笛卡尔积
export default {
  name: 'VariantAttr',
  props: {
    labelWidth: String,
    isEdit: Boolean,
    productLoading: Number,
    isVariation: Boolean,
    baseProductInfo: Object,
    itemId: String
    // totalSku: Array
  },
  data() {
    return {
      getRowKeys(row) {
        return row.id
      },
      colorVal: '',
      totalSku: [],
      tableTemp: 0,
      tableTitle: '',
      menApparelTable: [], // 男装尺码
      sizeOption: addListingHandle.sizeOption, // 尺码分类列表
      colorItem: addListingHandle.colorItem,
      colorList: [], // 勾选的颜色列表
      colorListTemp: [], // 勾选的颜色列表备份
      sizeList: [], // 勾选的尺码列表
      sizeListTemp: [], // 勾选的尺码列表备份
      areaSize: '', // 自定义尺码
      temp: '', // 中转值
      skuList: '',
      variantListStore: null,
      form: {
        color: [],
        variantList: variantList() // 笛卡尔积
      },
      childShoesList: [], // 童鞋尺码
      rules: {},
      // TODO mjf 已经选中的颜色和尺码的列表
      selectedSizeList: [],
      selectedColorList: []
    }
  },
  computed: {
    showSize() {
      return [3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27].includes(this.tableTemp)
    },
    filterDesc() {
      return descTitle[this.tableTemp - 17]
    }
  },
  watch: {
    baseProductInfo() {
      this.initializationData()
    }
  },
  mounted() {
    this.initializationData()
    // 获取所有商品编码
    this.getSkuDetailAjax(this.baseProductInfo.productSpu)
  },
  methods: {
    getSkuDetailAjax(productSku, storeCode, isVariationType) {
      getSpuDetailByProduct({ data: { lstProductSku: [productSku], platformCode: 'WH', storeCode: this.baseProductInfo.accountCode } }).then(res => {
        if (res.data && res.data[0]) {
          const data = res.data[0]
          this.totalSku = data.lstSku
          console.log('🚀 ~ file: variantAttr.vue ~ line 263 ~ getSpuDetailByProduct ~ this.totalSku', data, this.totalSku)
        } else {
        }
      }).finally(() => {
      })
    },

    // 初始变体值
    // initVariantList() {
    //   const skuList = this.isEdit ? this.baseProductInfo.wishListingVariantVOList : this.baseProductInfo.skuList
    //   skuList.forEach(item => { // 初始选中颜色
    //     this.form.color.push(item.color)
    //   })
    // },
    // 初始化数据 watch 第一次不会执行，需要初始化数据
    initializationData() {
      const { skuList, variantList, wishListingVariantVOList } = this.baseProductInfo
      let childProductSkuList = []
      if (this.isEdit) {
        childProductSkuList = wishListingVariantVOList.map(item => item.productSku)
      } else {
        childProductSkuList = skuList.map(item => item.productSku)
      }

      this.form = Object.assign({}, this.form, { skuList, variantList, childProductSkuList })
    },
    // 尺码 笛卡尔积
    changeMenApparelSize(val) {
      this.temp = val
      if (!val) return false
      // 子sku列表 销售利润率  运输时间
      const skuList = this.isEdit ? this.baseProductInfo.wishListingVariantVOList : variantList()
      const { profitRate, shippingTime, localizedShipping, msrp } = this.baseProductInfo
      if ([1, 2, 8, 9, 25].includes(this.tableTemp)) {
        this.sizeList = this.menApparelTable.filter(item => item.checked).map(acc => acc.size)
      }
      if (![1, 2, 8, 9, 25].includes(this.tableTemp)) {
        this.sizeList = val
      }
      // if (Array.isArray(val)) return
      let arr = [] // 属性值 二维数组
      this.sizeListTemp = this.sizeList
      this.colorListTemp = this.colorList
      arr = [this.sizeListTemp, this.colorListTemp]
      const combs = [] // 组合属性id:值;
      const recursion = (arr, index = 0, c = []) => {
        if (arr.length - 1 < index) return combs.push(c)
        arr[index].forEach(item => {
          recursion(arr, index + 1, c.concat(item))
        })
      }
      recursion(arr)
      const deepList = deepClone(skuList)
      const beforeVariantList = deepClone(this.form.variantList)
      // this.form.variantList = this.variantListStore ? this.variantListStore : deepList
      this.form.variantList = deepList
      // if (combs.length > 1) combs.splice(0, combs.length, combs[combs.length - 1])
      combs.forEach((citem, index) => {
        let sku = {}
        deepList && deepList.map(item => {
          // if(!item.productSku.lstAttrSpecification.length){}
          sku = {
            // id: `wish_variant${index}`,
            size: citem[0],
            // id: citem[0],
            color: citem[1],
            // productSku: item.productSku, // 子sku
            costPrice: item.costPrice,
            // costPrice: parseFloat(item.productCost * item.discountRatio).toFixed(2), //  成本 = 采购成本 *折扣
            msrp: msrp, // 参考价
            localizedShipping: localizedShipping, // 本地运费
            shipping: item.localizedShipping, // 运费
            localizedPrice: item.localizedPrice, // 售价
            profitRate: profitRate, // 利润率
            shippingTime: shippingTime // 运输时间
          }
        })
        this.form.variantList.push(sku)
      })
      // 删除第一条初始化数据
      if (!this.isEdit) this.form.variantList.splice(this.form.variantList.findIndex(item => !item.size && !item.color), 1)
      const arr1 = []
      this.form.variantList.forEach((item, i) => {
        arr1.push(Object.assign({}, item, beforeVariantList[i], {
          size: item.size,
          color: item.color
        }))
      })
      this.form.variantList = arr1
      // if (!val.checked) this.form.variantList.splice(this.form.variantList.findIndex(item => item.size === val.size), 1)
      // if (type === 'changeSize') this.form.variantList = skuList
      this.$set(this.form.variantList)
      this.colorListTemp = []
      this.sizeListTemp = []
    },
    // TODO mjf
    sizeChange(val) {
      const checked = val.checked
      const selectedSize = val.size
      if (checked) {
        const alreadySelectedSize = this.selectedSizeList.filter(size => size === selectedSize)
        const originVariantSize = this.form.variantList.length
        if (alreadySelectedSize.length === 0) {
          this.selectedSizeList.push(selectedSize)
        }
        const selectedColorSize = this.selectedColorList.length
        if (selectedColorSize === 0) {
          const item = this.createVariant()
          item.size = selectedSize
          item.index = selectedSize
          const existsVariantList = this.form.variantList.filter(variant => variant.index === item.index)
          if (existsVariantList.length === 0) {
            this.form.variantList.push(item)
          }
        } else {
          const currentVariant = this.selectedColorList.length * this.selectedSizeList.length
          if (currentVariant > originVariantSize) {
            const newVariantList = []
            this.selectedColorList.forEach(color => {
              const newVariant = this.createVariant()
              newVariant.size = selectedSize
              newVariant.color = color
              newVariant.index = newVariant.color + '_' + newVariant.size
              newVariantList.push(newVariant)
            })
            newVariantList.forEach(variant => this.form.variantList.push(variant))
          } else {
            // 如果之前变体的数量和现在新生成的变体的数量相等，那么直接将size赋值给变体的size即可
            this.form.variantList.forEach(variant => {
              variant.size = selectedSize
            })
          }
        }
      } else {
        this.selectedSizeList = this.selectedSizeList.filter(size => size !== selectedSize)
        if (this.selectedSizeList.length > 0) {
          this.form.variantList = this.form.variantList.filter(vairant => vairant.size !== selectedSize)
        } else {
          if (this.selectedColorList.length === 0) {
            this.form.variantList = []
          } else {
            this.form.variantList.forEach(variant => {
              variant.size = ''
              variant.index = variant.color
            })
          }
        }
      }
    },
    colorChange(val) {
      const selectedColor = val[val.length - 1]
      const originColorLength = this.selectedColorList.length
      if (originColorLength <= val.length) {
        const alreadySelectedColor = this.selectedSizeList.filter(color => color === selectedColor)
        const originVariantSize = this.form.variantList.length
        if (alreadySelectedColor.length === 0) {
          this.selectedColorList.push(selectedColor)
        }
        const selectedSizeLength = this.selectedSizeList.length
        if (selectedSizeLength === 0) {
          const item = this.createVariant()
          item.color = selectedColor
          item.index = selectedColor
          const existsVariantList = this.form.variantList.filter(variant => variant.index === item.index)
          if (existsVariantList.length === 0) {
            this.form.variantList.push(item)
          }
        } else {
          const currentVariantLength = this.selectedColorList.length * this.selectedSizeList.length
          if (currentVariantLength > originVariantSize) {
            const newVariantList = []
            this.selectedSizeList.forEach(size => {
              const newVariant = this.createVariant()
              newVariant.size = size
              newVariant.color = selectedColor
              newVariant.index = newVariant.color + '_' + newVariant.size
              newVariantList.push(newVariant)
            })
            newVariantList.forEach(variant => this.form.variantList.push(variant))
          } else {
            // 如果之前变体的数量和现在新生成的变体的数量相等，那么直接将size赋值给变体的size即可
            this.form.variantList.forEach(variant => {
              variant.color = selectedColor
            })
          }
        }
      } else {
        if (val.length === 0) {
          if (this.selectedSizeList.length > 0) {
            this.form.variantList.forEach(vairant => {
              vairant.color = ''
            })
          } else {
            this.form.variantList = []
          }
          this.selectedColorList = []
        } else {
          const colorList = []
          const excludeColorList = []
          this.selectedColorList.filter(originColor => {
            const filterColorList = val.filter(currentColor => originColor === currentColor)
            if (filterColorList.length > 0) {
              colorList.push(originColor)
            } else {
              excludeColorList.push(originColor)
            }
          })
          this.selectedColorList = colorList
          if (excludeColorList.length > 0) {
            var variantList = []
            excludeColorList.forEach(excludeColor => {
              this.form.variantList.forEach(vairant => {
                if (vairant.color !== excludeColor) {
                  variantList.push(vairant)
                }
              })
            })
            this.form.variantList = variantList
          }
        }
      }
    },
    createVariant() {
      const item = {}
      item.size = null
      item.color = null
      item.price = null
      item.localizedPrice = null
      item.profitRate = null
      item.productSku = null
      item.index = ''
      return item
    },
    // 颜色链接
    handleColorCell() {
      const url = 'https://merchant.wish.com/documentation/colors'
      window.open(url, '_blank')
    },
    // 添加 面积或体积 长度 体积 尺码
    addArea(area) {
      this.menApparelTable.push(area)
      this.areaSize = ''
    },
    // 切换商品编码
    changeProductSku(val, row, index) {
      // 子sku去重
      const variantAttr = deepClone(this.form.variantList)
      variantAttr.splice(index, 1)
      for (let i = 0; i < variantAttr.length; i++) {
        if (variantAttr[i].productSku === row.productSku) {
          row.productSku = ''
          return this.$message.error('子sku不能重复')
        }
      }
      this.variantListStore = this.isEdit ? this.baseProductInfo.wishListingVariantVOList : variantList()
      const costList = this.isEdit ? this.baseProductInfo.wishListingVariantVOList : this.baseProductInfo.skuList
      costList.forEach(item => {
        if (item.productSku === val) {
          row.costPrice = item.costPrice
        }
      })
      this.form.variantList.map(item => {
        if (item.productSku === row.productSku) item.costPrice = row.costPrice
        return item
      })
      this.variantListStore = this.form.variantList
      // 成本显示
      if (!row.profitRate && row.localizedPrice) return this.$message.error('售价和利润率都不能为空')
      if (row.profitRate) { // 有利润率就调用计算售价的接口
        this.changeProfitRate(row, index)
      }
      if (row.localizedPrice) { // 有售价就调用 计算利润率的接口
        this.handleLocalizedPrice(row, index)
      }
    },
    // 计算利润率
    handleLocalizedPrice(row, index) {
      if (!row.productSku) return this.$message.error('请选择商品编码')
      const { accountCode, warehouseId } = this.baseProductInfo
      const priceRateDTOList = []
      priceRateDTOList.push({ price: Number(row.localizedPrice) + Number(this.baseProductInfo.localizedShipping), productSku: row.productSku, productCost: row.costPrice })
      const params = {
        storeCode: accountCode, // 店铺编码
        warehouseId: warehouseId, // 仓库编码
        platformCode: 'WH', // 平台编码
        priceRateDTOList: priceRateDTOList,
        productCost: row.productCost // 采购成本
      }
      calculateProfitRate(params).then(res => {
        const data = res.data
        this.$set(this.form.variantList[index], 'profitRate', data[row.productSku].profitRate)
      })
    },
    validateProfitRate(sku, index) {
      return (rule, value, callback) => {
        if (sku.profitRate && sku.profitRate > 0) {
          callback()
        } else {
          callback(new Error('利润率不能小于0'))
        }
      }
    },
    validateCostPrice(sku, index) {
      return (rule, value, callback) => {
        if (sku.costPrice && sku.costPrice > 0) {
          callback()
        } else {
          callback(new Error('成本不能小于0'))
        }
      }
    },
    // 更新售价
    changeProfitRate(row, index) {
      if (!row.productSku) return this.$message.error('请选择商品编码')
      this.getCalculatePrice(row.productSku, row.profitRate, row.costPrice, index)
    },
    // 计算售价
    getCalculatePrice(productSku, profitRate, costPrice, index) {
      const { accountCode, warehouseId } = this.baseProductInfo
      const priceDTOList = [{ productSku: productSku, saleProfitRate: profitRate, productCost: costPrice }]
      const params = {
        storeCode: accountCode, // 店铺编码
        warehouseId: warehouseId, // 本地仓库编码
        platformCode: 'WH', // 平台编码
        priceDTOList: priceDTOList, // 多变体列表
        saleProfitRate: profitRate, // 销售利润率
        productSku: productSku // 子sku
      }
      calculatePrice(params).then(res => {
        const data = res.data
        const salePrice = Number(data[productSku].salePrice) - Number(this.baseProductInfo.localizedShipping)
        this.$set(this.form.variantList[index], 'localizedPrice', salePrice.toFixed(2))
      })
    },
    changeColor(val) {
      this.colorList = val
      this.changeMenApparelSize(this.temp)
    },
    // 切换尺码类型
    changeSize(val) {
      this.variantListStore = null
      if (this.tableTemp === val.value) return
      this.tableTemp = val.value
      this.childShoesList = []
      const num = addListingHandle.MenApparel()[val.value - 1]
      // const cartesianList = this.form.variantList.filter(item => { item.size = '' })
      // TODO mjf
      // this.form.variantList = this.isEdit ? this.baseProductInfo.wishListingVariantVOList : []
      this.menApparelTable = num
      this.tableTitle = val.label
      // this.changeMenApparelSize(this.temp, 'changeSize')
    },
    // 添加颜色
    addColorVal() {
      if (this.colorVal) {
        this.colorItem.push({ color: '', label: this.colorVal })
        this.colorVal = ''
      }
    },
    // 添加多变体
    handlerAdd(row, index) {
      this.form.variantList.push(variantList())
    },
    // 删除多变体
    handlerDel(row, index) {
      this.form.variantList.splice(index, 1)
    }
  }
}
</script>

<style lang="scss" scoped>
::v-deep .el-table--enable-row-transition .el-table__body td{
  padding:2px 0 !important;
}
.w-90{
  width: 90%;
}
.w-20{
  width: 20%;
}
.color{
  width: 22px;
  height: 14px;
  margin-right: 10px;
  display:inline-flex;
  background-size: 20px 12px !important;
  vertical-align: middle;
}
.herfColor{
  color:#409EFF
}
.sizeList{
  list-style: none;
  display: flex;
  flex-wrap:wrap;
  margin: 0 0 0 -40px;
  flex-direction:row;
  li{
    margin-right:10px;
    cursor: pointer;
    font-size: 14px;
    padding:0 2px;
    span{
      font-size: inherit;
    }

  }
}
.active{
  color: #409EFF;
}
.has-error{
  padding-left: 10px;
  position: relative;
  &::before{
    content: "*";
    display: inline-block;
    color: #F56C6C;
    position: absolute;
    left: 0;
    top: 0;
  }
}
.el-form-item_no-lable ::v-deep .el-form-item__content{
  margin-left: 0 !important;
}
.form-table{
  .el-form-item--mini.el-form-item{
    margin-bottom: 0;
  }
  ::v-deep .el-form-item__error{
    position: initial;
    font-weight: 400;
  }
}
</style>

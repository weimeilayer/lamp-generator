<template>
  <div class="bg-white m-4 mr-2 overflow-hidden">
    <div class="m-4">
      <a-button @click="handleAdd()" class="mr-2"> 新增根节点 </a-button>
      <a-button @click="handleBatchDelete()" class="mr-2"> 删除 </a-button>
    </div>
    <BasicTree
      :title="t('${cfg.projectPrefix}.${cfg.childPackageName}.${entity?uncap_first}.table.title')"
      toolbar
      checkable
      search
      :actionList="actionList"
      :beforeRightClick="getRightMenuList"
      :clickRowToExpand="true"
      :treeData="treeData"
      :replaceFields="{ key: 'id', title: 'label' }"
      @select="handleSelect"
      ref="treeRef"
    />
  </div>
</template>
<script lang="ts">
  import { defineComponent, onMounted, ref, unref, h } from 'vue';
  import { PlusOutlined, DeleteOutlined } from '@ant-design/icons-vue';
  import { useI18n } from '/@/hooks/web/useI18n';
  import { useMessage } from '/@/hooks/web/useMessage';
  import {
    BasicTree,
    TreeItem,
    ActionItem,
    TreeActionType,
    ContextMenuItem,
  } from '/@/components/Tree';
  import { findNodeByKey } from '/@/utils/${cfg.projectPrefix}/common';

  import { tree, remove } from '/@/api/${cfg.projectPrefix}/${cfg.childPackageName}/${entity?uncap_first}';

  export default defineComponent({
    name: '${entity}Management',
    components: { BasicTree },

    emits: ['select', 'add'],
    setup(_, { emit }) {
      const { t } = useI18n();
      const { createMessage, createConfirm } = useMessage();
      const treeRef = ref<Nullable<TreeActionType>>(null);
      const treeData = ref<TreeItem[]>([]);

      function getTree() {
        const tree = unref(treeRef);
        if (!tree) {
          throw new Error('树结构加载失败,请刷新页面');
        }
        return tree;
      }

      onMounted(() => {
        fetch();
      });

      // 加载数据
      async function fetch() {
        treeData.value = ((await tree()) as unknown) as TreeItem[];
      }

      // 选择节点
      function handleSelect(keys: string[]) {
        if (keys[0]) {
          const node = findNodeByKey(keys[0], treeData.value);
          const parent = findNodeByKey(node?.parentId, treeData.value);
          emit('select', parent, node);
        }
      }

      // 悬停图标
      const actionList: ActionItem[] = [
        {
          render: (node) => {
            return h(PlusOutlined, {
              class: 'ml-2',
              onClick: (e) => {
                e.stopPropagation();
                emit('add', findNodeByKey(node.id, treeData.value));
              },
            });
          },
        },
        {
          render: (node) => {
            return h(DeleteOutlined, {
              class: 'ml-2',
              onClick: (e) => {
                e.stopPropagation();
                batchDelete([node.id]);
              },
            });
          },
        },
      ];

      // 右键菜单
      function getRightMenuList(node: any): ContextMenuItem[] {
        return [
          {
            label: '新增',
            handler: (e) => {
              e.stopPropagation();
              emit('add', findNodeByKey(unref(node.$attrs).id, treeData.value));
            },
            icon: 'bi:plus',
          },
          {
            label: '删除',
            handler: (e) => {
              e.stopPropagation();
              batchDelete([node.id]);
            },
            icon: 'bx:bxs-folder-open',
          },
        ];
      }

      // 执行批量删除
      async function batchDelete(ids: string[]) {
        createConfirm({
          iconType: 'warning',
          content: '选中节点及其子结点将被永久删除, 是否确定删除？',
          onOk: async () => {
            await remove(ids);
            createMessage.success(t('common.tips.deleteSuccess'));
            fetch();
          },
        });
      }

      // 点击组织数外面的 新增
      function handleAdd() {
        emit('add', findNodeByKey('0', treeData.value));
      }

      // 点击组织数外面的 批量删除
      function handleBatchDelete() {
        const ids = getTree().getCheckedKeys() as string[];
        if (!ids || ids.length <= 0) {
          createMessage.warning(t('common.tips.pleaseSelectTheData'));
          return;
        }
        batchDelete(ids);
      }

      return {
        t,
        treeRef,
        treeData,
        fetch,
        handleAdd,
        handleBatchDelete,
        getRightMenuList,
        actionList,
        handleSelect,
      };
    },
  });
</script>

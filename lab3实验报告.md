# 操作系统lab3
### 庞艾语2211581 董圣娇2212481 刘星宇2212824
### Problem1：**理解基于**FIFO**的页面替换算法（思考题）**

> ###### 描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？至少正确指出10个不同的函数分别做了什么？要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数。

当程序触发页异常的时候，会进入对应的处理程序 `pgfault_handler` 函数，在此函数中会调用 `print_pgfault` 打印错误信息，以及将这些错误信息交给 `do_pgfault` 函数处理。

```c
static int pgfault_handler(struct trapframe *tf) {
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
    }
    panic("unhandled page fault.\n");
}
```

在`do_pgfault` 函数中，首先调用`find_vma`函数，其会找到一个满足条件的`vma`结构体，此处是判断地址是否合法。

```c
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
```

```c
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL;
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}
```

然后调用`get_pte`函数，`get_pte`查找某个虚拟地址对应的页表项，如果不存在这个页表项，会为它分配一个全是0的页并建立映射。最后返回虚拟地址对应的一级页表的页表项。

如果页表项全零，这个时候就会调用 `pgdir_alloc_page` 。首先会调用`alloc_page` 函数。

```c
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
```

该函数的作用是：分配指定数量的页并返回一个指向分配的页的指针。目的是为了在系统内存不足时，通过交换（swap）来释放一些页面以获得空闲页，以供进一步的内存分配使用。 



在该函数中，会调用 `swap_out` 函数。

```c
int
swap_out(struct mm_struct *mm, int n, int in_tick)
{
     int i;
     for (i = 0; i != n; ++ i)
     {
          uintptr_t v;
          //struct Page **ptr_page=NULL;
          struct Page *page;
          // cprintf("i %d, SWAP: call swap_out_victim\n",i);
          int r = sm->swap_out_victim(mm, &page, in_tick);
          if (r != 0) {
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
                  break;
          }          
          //assert(!PageReserved(page));

          //cprintf("SWAP: choose victim page 0x%08x\n", page);
          
          v=page->pra_vaddr; 
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
          assert((*ptep & PTE_V) != 0);

          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
                    free_page(page);
          }
          
          tlb_invalidate(mm->pgdir, v);
     }
     return i;
}
```

该函数的作用是：将指定数量的页面从内存中交换到磁盘的交换空间中。 

1. 在函数中，使用一个循环来遍历需要交换的页面个数。在循环内部，首先定义了一个 uintptr_t 类型的变量 v，用于保存页面的虚拟地址。 
2. 然后调用 `sm->swap_out_victim()` 函数来选择一个页面作为交换的牺牲品（victim），并将选中的页面的指针保存在结构体变量 `page` 中。如果选择失败（r != 0），则输出错误信息，并退出循环。
3. 接下来通过 `get_pte()` 函数获取页面对应的页表项（`pte_t`），并通过 assert() 断言确保页面的 `PTE_V` 标志位为 1，即页表项有效。
4. 然后，调用 `swapfs_write()` 函数将页面写入磁盘的交换空间中。如果写入失败，则输出错误信息，并通过 sm->map_swappable() 函数将页面重新设为可交换状态。如果写入成功，输出交换的信息，并更新页表项的内容，并释放页面占用的内存。 
5. 最后，调用 `tlb_invalidate()` 函数来使 TLB（翻译后备缓存）失效，以确保下次访问替换后的页面时，能够重新加载最新的页表项信息。 函数返回循环计数器 i，表示成功交换的页面数目。



`swap_out` 函数找到应该换出的页面则是通过 `fifo_swap_out_victim` 实现的。

```c
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```

该函数的作用是：从一个双向链表中选择一个最早到达的页面作为牺牲者页面进行置换，并将该页面的指针存储在`ptr_page`中返回。它首先检查链表是否为空，如果不为空，则选择最早到达的页面，将其从链表中删除，并将其地址存储在`ptr_page`中。如果链表为空，就将`ptr_page`设置为NULL。



在 `pgdir_alloc_page` 调用 `alloc_page` 获得分配的页面后会调用 `page_insert` 函数。

```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
        struct Page *p = pte2page(*ptep);
        if (p == page) {
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
    tlb_invalidate(pgdir, la);
    return 0;
}
```

该函数的作用是：向页表中插入新页表项。

1. 将页目录表和线性地址作为参数传入函数。 
2. 通过调用`get_pte`函数获取线性地址对应的页表项指针`ptep`。 
3. 如果获取到的`ptep`为空，表示没有足够的内存来创建页表项，返回错误码`-E_NO_MEM`。 
4. 增加页面的引用计数，使其在内存中得以被引用。 
5. 如果获取到的页表项`*ptep`已经有效（存在于物理内存中），则说明该页表项已被使用。   
   - 如果获取到的页表项`*ptep`对应的页面与新页面`page`是同一个页面，说明新页面已经被插入到相应的页表项，无需额外操作。  
   - 如果获取到的页表项对应的页面与新页面不是同一个页面，说明该页表项与其他页面关联，需要先将该页表项与其他页面解除关联。 

6. 使用`pte_create`函数创建新的页表项，其中包括新页面的物理页号和权限信息。 
7. 将新的页表项写入到获取到的`ptep`中，完成对页表的更新。 
8. 通过调用`tlb_invalidate`函数刷新TLB缓存，确保新的页面映射生效。 
9. 返回0，表示插入操作成功。



然后 `pgdir_alloc_page` 会调用 `swap_map_swappable` 函数。作用是将页面加入相应的链表，设置页面可交换。

```c
int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
}
```

如果 `do_pgfault` 函数获取 `addr` 函数对应的 `pte` 不为空的话，则首先会调用 `swap_in` 函数。

```c
int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
{
     struct Page *result = alloc_page();
     assert(result!=NULL);

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
     // cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
    
     int r;
     if ((r = swapfs_read((*ptep), result)) != 0)
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
     *ptr_result=result;
     return 0;
}
```

该函数的作用是：用于将磁盘上的页面交换到内存中。

1. 首先，函数通过调用`alloc_page()`分配一个新的页面，将其赋值给`result`指针。 
2. 接下来，函数使用`get_pte()`函数根据给定的虚拟地址`addr`和页目录`pgdir`获取相应的页表项`ptep`。 
3. 通过调用`swapfs_read()`函数，将磁盘上的交换项读取到刚刚分配的页面中。`swapfs_read()`函数的返回值`r`用于检查读取操作是否成功。 
4. 如果读取操作成功，函数会将读取到的页面地址赋值给`ptr_result`指针，以便在函数外部进行后续处理。 
5. 最后，函数返回0，表示页面成功加载到内存中。

`lab3/kern/mm/swap_fifo.c`中还有以下函数：

```c
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation

    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}
/*
```

该函数的作用是：将一个页面添加到最近访问页面队列的末尾，以便进行页面置换（swap）操作时，按照先进先出（FIFO）的原则决定置换的页面。 `list_add(head, entry);` 将entry指针所指的list_entry_t节点插入到head指针所指的队列（pra_list_head队列）的末尾。

```c
static int
_fifo_check_swap(void) {
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    ...
    assert(pgfault_num==11);
    return 0;
}
```

该函数的作用是：检查页置换算法中的先进先出（FIFO）算法是否正常工作。 代码逻辑是在不同的虚拟地址写入不同的值，并使用断言来检查页面错误的次数是否符合预期。它为了测试页面置换算法的正确性，并对页面错误的次数进行了断言校验。

```c
int
swap_init(void)
{
     swapfs_init();

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
     int r = sm->init();
     
     if (r == 0)
     {
          swap_init_ok = 1;
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
```

该函数的作用是：在系统启动时进行交换空间的初始化操作，并使用先进先出（FIFO）的页面置换算法进行交换管理。

1. 首先，函数调用`swapfs_init()`初始化了交换文件系统。交换文件系统是计算机用来存储和管理交换空间的一种文件系统。 
2. 接着，代码检查了`max_swap_offset`的取值范围是否满足条件。`max_swap_offset`表示交换空间的最大偏移量，这里限制了它的取值在7到MAX_SWAP_OFFSET_LIMIT之间（不包括MAX_SWAP_OFFSET_LIMIT）。如果不满足这个条件，就会触发一个panic（即宕机）。 
3. 然后，代码使用了"Clock"页面置换算法（Page Replacement Algorithm）进行交换管理器（swap manager）的初始化。`sm`是一个指向`swap_manager_clock`的指针，`swap_manager_clock`是一个具体的交换管理器，采用先进先出（FIFO）的方式进行页面置换。 函数调用`sm->init()`进行具体的交换管理器初始化，并将初始化的结果保存在变量`r`中。 
4. 最后，代码根据`init()`函数的返回值`r`判断初始化是否成功。如果初始化成功，将`swap_init_ok`置为1，打印出当前使用的交换管理器的名称，并调用`check_swap()`函数进行交换空间的一些检查。 最后返回变量`r`，表示初始化的结果。

```c
static void
check_swap(void)
{
...
	cprintf("count is %d, total is %d\n",count,total);
    //assert(count == 0);
     
    cprintf("check_swap() succeeded!\n");
}
```

该函数的作用是：检查页交换（page swap）机制的正确性，包括备份和恢复内存环境、设置页面替换算法的初始环境、访问虚拟页面以测试页面替换算法等。

### 练习2：深入理解不同分页模式的工作原理（思考题）

> ###### get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像；目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

1.   get_pte函数中这两段代码看起来很相似，因为它们都在做同样的事情——处理页表的两级映射结构，只是在不同级别的页表中。这种设计使得虚拟内存系统可以灵活地支持不同大小的地址空间，同时还可以有效地管理内存。例如，在SV32中只有两级页表，而在SV39和SV48中则有更多级别的页表。

```c
    pde_t *pdep1 = &pgdir[PDX1(la)];
// PDX(la) = 获取虚拟地址la的PDE索引。
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
//    PDE(la)=获取虚拟地址的次级页表索引
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```

- 第一段代码处理的是一级页表，也就是页目录。首先检查对应级别的页目录项（PDE）是否存在。如果不存在，并且create标志为真，那么就会分配一个新的页面，并将其设置为页目录项。然后，将新分配的页面的物理地址转换为内核虚拟地址，并将其内容清零。
- 而第二段代码处理的是二级页表。首先检查对应级别的页表项（PTE）是否存在。如果不存在，并且create标志为真，那么就会分配一个新的页面，并将其设置为页表项。然后，将新分配的页面的物理地址转换为内核虚拟地址，并将其内容清零。

2) 将页表项的查找和分配合并在一个函数中的优点是它可以简化调用者的代码，因为调用者不需要显式地检查页表项是否存在，然后再决定是否需要创建新的页表项。然而函数的名字（get_pte）没有明确表示出它可能会创建新的页表项。其次，如果只想获取已经存在的页表项，而不想创建新的页表项，那么这个函数就无法满足需求。
   我认为没有必要拆开，因为这样做可以简化代码并减少错误的发生。

### 练习3：给未被映射的地址映射上物理页（需要编程）
```c
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：

请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？
```
- 实现代码：
![hit](fig\ex3.png)
- 详细说明实现过程：
 if(swap_in(mm,addr,&page))：
 这行代码调用swap_in函数，尝试从交换空间中加载页面到物理内存。mm是内存管理结构，addr是虚拟地址，page是指向页面结构的指针。如果加载成功，swap_in返回0（假），否则返回非0值（真）。
cprintf("swap page in do_pgfault failed\n");：
如果swap_in返回真，表示加载失败，这里使用cprintf（可能是内核中的打印函数）打印错误信息。
page_insert(mm->pgdir,page,addr,perm);：
如果加载成功，调用page_insert函数，将加载的页面插入到内存管理结构mm的页目录pgdir中，建立物理地址和虚拟地址之间的映射。perm是页面的权限设置。
swap_map_swappable(mm,addr,page,1);：
调用swap_map_swappable函数，将页面标记为可交换的。
page->pra_vaddr = addr;：
将页面结构中的pra_vaddr字段设置为虚拟地址addr，记录页面的虚拟地址。
- Page Directory Entry和Page Table Entry对ucore实现页替换算法的潜在用处。
 Page Directory Entry通常包含以下组成部分：

   - 物理页面号：指向包含页表项的物理页面的地址。
   - 存在位（Present bit）：指示该页表是否存在。如果该位为0，表示该页表项不在物理内存中，可能需要从磁盘加载。
   - 读/写位（Read/Write bit）：控制对页面的访问权限，区分只读和可读写。
   - 用户/超级用户位（User/Supervisor bit）：区分用户模式和内核模式的访问权限。
   - 页表修改位（Page Table Dirty bit）：指示页表项是否被修改过，用于决定是否需要写回磁盘。
   - 访问位（Accessed bit）：记录页面是否被访问过，用于页替换算法中的最近最少使用（LRU）策略。
   - 缓存使能位（Cache Enable bit）：控制页面是否可以被缓存。

  Page Table Entry包含一下组成部分：
   - 物理页面号：指向包含数据的物理页面的地址。
   - 存在位（Present bit）：指示该页面是否存在。如果该位为0，表示该页面不在物理内存中，可能需要从磁盘加载。
   - 读/写位（Read/Write bit）：控制对页面的访问权限。
   - 用户/超级用户位（User/Supervisor bit）：区分用户模式和内核模式的访问权限。
   - 页面修改位（Page Dirty bit）：指示页面是否被修改过，用于决定是否需要写回磁盘。
   - 访问位（Accessed bit）：记录页面是否被访问过，用于页替换算法中的LRU策略。
   - 缓存使能位（Cache Enable bit）：控制页面是否可以被缓存。

  对ucore实现页替换算法的潜在用处：
  - 访问位（Accessed bit）：用于跟踪页面的访问模式，帮助实现LRU算法。通过检查访问位，操作系统可以确定哪些页面最近被访问过，从而决定哪些页面应该被替换。
  - 页面修改位（Page Dirty bit）：用于确定页面是否需要在替换前写回磁盘。如果页面被修改过，它需要先写回磁盘，然后再从磁盘加载新的页面。
  - 存在位（Present bit）：用于快速检查页面是否在物理内存中。如果页面不在内存中，操作系统需要从磁盘加载页面，这通常涉及到交换（swap）操作。
  - 读/写位（Read/Write bit）：控制对页面的访问权限，确保安全性。在页替换过程中，这些位可以用来决定哪些页面可以被修改，哪些只能被读取。
  - 用户/超级用户位（User/Supervisor bit）：区分用户模式和内核模式的访问权限，确保内核页面不会被用户程序错误地访问或修改。
  - 缓存使能位（Cache Enable bit）：控制页面是否可以被缓存。在页替换算法中，这些位可以用来优化缓存的使用，提高内存访问效率。
- 出现了页访问异常时，硬件需要执行以下操作：
  - 保存当前CPU寄存器的状态：硬件会自动保存当前进程的上下文，包括程序计数器（PC）和其他相关寄存器状态等，将这些信息保存在内核栈中或者特定的异常堆栈中。


  - 触发异常处理：当处理器检测到对一个没有合法物理页面映射的虚拟地址的访问时，会触发页访问异常，将控制权转移到操作系统内核的页访问异常处理例程。

  - 切换特权级别：硬件会将处理器的特权级别从用户模式切换到内核模式，以便访问操作系统的数据结构和指令。

  - 提供异常信息：硬件会将引发异常的原因和相关信息（如错误码）传递给操作系统，帮助操作系统确定异常的具体类型和原因。

  - 保存发生页访问异常的地址：硬件将发生页访问异常的地址保存在特定的寄存器中，例如在x86架构中是CR2寄存器，在RISC-V架构中是stval寄存器。

  - 生成一个错误码：硬件会生成一个错误码，并将其压入当前栈中。错误码包含引起异常的原因（例如页面不存在、访问权限错误等）
  - 转入异常处理程序：硬件通过中断或异常处理机制，跳转到操作系统的页故障处理例程进行处理
- 对应关系：
  在操作系统中，Page数据结构通常用于表示物理内存中的一个页面。这个数据结构的全局变量（通常是一个数组）中的每一项代表一个物理页面，并且与页表中的页目录项（Page Directory Entry）和页表项（Page Table Entry）有直接的对应关系。这种对应关系是操作系统内存管理的核心部分，用于跟踪和管理物理内存中的页面。
    - 物理页面与页表项（Page Table Entry）：每个物理页面由一个Page结构表示，这个结构中通常包含该页面的物理地址、状态（如是否在使用、是否可交换等）、引用计数等信息。当操作系统创建或更新一个页表项时，它会将该页表项指向一个物理页面。页表项中的物理页面号（Physical Page Number, PPN）就是指向这个Page结构的物理地址。
  - 全局Page数组与页表：全局Page数组中的每个元素代表一个物理页面，操作系统使用这个数组来跟踪所有可用的物理页面。当操作系统需要为某个虚拟地址分配物理内存时，它会从这个数组中选择一个空闲的Page，然后在相应的页表项中设置物理页面号，指向这个Page。

### 练习4：补充完成Clock页替换算法（需要编程）
```
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程，同时比较Clock页替换算法和FIFO算法的不同。  
```
- Clock替换算法实现：
  - clock_init_mm:
![hit](fig\ex41.png)
  基本实现了clock替换的初始化：
   list_init(&pra_list_head);初始化pre_list_head为空链表；
   curr_ptr = &pra_list_head;初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
   mm->sm_priv = &pra_list_head;将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
  - clock_map_swappable:
![hit](fig\ex42.png)   
   把最近访问的页面放到队列的尾部：
  list_entry_t *head = (list_entry_t*) mm->sm_priv;获取指向页面链表头部的指针head，这个头部指针存储在mm->sm_priv中。
  list_add(head, entry);将页面链表项entry插入到链表head的末尾，双向链表，相当于插入了链表尾部。
  page->visited = 1;再将visited设置为1，表明已经访问过了。
  - clock替换：
![hit](fig\ex43.png)
while循环遍历页面链表，查找最早未被访问的页面。
如果curr_ptr等于head，则将curr_ptr移动到链表的末尾。
使用le2page宏将链表项转换为Page结构指针。
如果当前页面未被访问（ptr->visited == 0），则将该页面指针赋值给ptr_page，从链表中删除该页面，并退出循环。
如果当前页面已被访问，则将visited标志置为0，并继续遍历链表。
- Clock替换算法与FIFO算法的区别：
  - FIFO算法按照页面进入内存的顺序来选择换出页面。最早进入内存的页面将最先被换出。通常使用一个队列来管理页面，新页面进入时排在队列的末尾，当需要换出页面时，队列头部的页面被换出。
  优点：
  它的优点是实现简单。
  缺点：
  不考虑页面的使用频率，可能导致频繁访问的页面被换出，引起抖动（thrashing），以及长时间运行的进程可能会导致其页面长时间占用内存，影响其他进程。
      
  - 时钟算法是FIFO算法的改进版，它引入了一个“访问位”（或称为“使用位”）来跟踪页面是否被访问过。算法按照页面进入内存的顺序选择换出页面，但会优先考虑那些未被访问的页面。clock算法使用一个双向链表来管理页面，类似于FIFO算法的队列，每个页面都有一个“访问位”，从链表头部开始，按顺序检查页面，如果页面未被访问，则将其换出，如果页面已被访问，则清除其“访问位”并继续检查下一个页面。
优点：
考虑了页面的使用频率，减少了频繁访问页面被换出的情况。
通过“访问位”机制，可以更好地适应页面的访问模式，减少抖动。
缺点：
相对于FIFO算法，实现稍微复杂一些。
### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
```
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？  
```
 "一个大页"方式是指直接使用较大的页表来映射整个虚拟地址空间。每个页表项映射较大的物理内存块。

 **优势**
- 减少页表级数，减少内存访问次数，访问更快：
每次虚拟地址到物理地址的转换中，分级页表需要多次内存访问（每一级页表一次）。
"一个大页"方式只需访问一级页表。可以减少页表的访问次数，加快地址转换的速度。

- 节省页表内存:
分级页表需要为每一级分配内存，可能会浪费大量空间，尤其是多级页表中未使用的部分。
"一个大页"方式直接用一个大块页表覆盖，节省内存，更适合内存有限的系统。

- 提高TLB命中率：
因为一个大页所涵盖的地址范围更广，相对于小页，大页在TLB中的缓存命中率更高，从而减少了页表查找的开销，降低了 TLB 的压力。



**劣势**

- 内存碎片问题：
一个大页可能会映射较大的内存块，但程序可能只使用了其中的一部分，导致内存碎片，大量未使用的内存浪费，会降低内存利用率。

- 页面置换时的代价：
分级页表中，虚拟地址到物理地址的映射是按较小的粒度（如 4 KiB）管理的，可以更细粒度地换出和换入页面。
当使用大页时，如果需要将一个大页从物理内存中换出，会导致一次较大数据量的I/O操作，换出操作需要更长的 I/O 时间，磁盘的吞吐能力可能成为瓶颈，导致性能下降。

- 缺乏灵活性：
分级页表可以按需分配页表和内存块，灵活调整虚拟地址空间。
"一个大页"方式不能做到按需分配，必须一次性分配较大的内存块。

- TLB失效的代价更高：
使用大页时，虽然提高了 TLB 的命中率，但一旦发生 TLB 失效（TLB Miss），其代价会比小页模式更高。这主要是因为大页在 TLB 中涵盖的地址范围更广，TLB 失效导致丢失的映射范围更大。




### 扩展：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

#### LRU算法实现思路：

**数据结构**：双向链表形式的队列，`pra_list_head`指针用来索引所有可交换的空闲页帧。当某页帧被访问后，就将该页帧`page`的指针`pra_page_link`更新到队列尾，当需要换出一个页时，选择队列首指向的页换出去即可，并更新这个队列。

当访问一个页帧时，会有两种情况：
- `HIT` ：直接定位到相应页帧的物理地址进行读写操作即可。
- `FAULT`：此时函数调用流程为（使用LRU替换算法）：当物理内存还够用时，`do_pgfault`—>`_lru_map_swappable`，当物理内存不够用时，`do_pgfault`—>`_lru_swap_out_victim`—>`_lru_map_swappable`


具体来说，当访问页的结果是`HIT`时，需要将此页的指针（已存在于队列中）移动到队尾，或者先删除然后添加到队尾；当访问页的结果是`FAULT`时，物理内存不够用时，先在`_lru_swap_out_victim`里从队列里删除换出去的页帧的`pra_page_link`，然后在`_lru_map_swappable`中将换入的页帧的`pra_page_link`添加到队尾，够用则直接添加即可。

设置了如下两个函数，分别处理`HIT`和`FAULT`时对链表的更新操作。

```cpp

static void _lru_hit_find(uintptr_t addr);
static void _lru_fault_find(struct Page *page);
```

为实现`HIT`时的操作，在`check`函数中每个测试用例下都得加处理函数——都是`_lru_hit_find`函数。全局变量`IsFault`来判断执行`_lru_hit_find`时是直接`HIT`后来执行的还是`FAULT`处理完成后重新来执行的。

### 测试分析


前四个测试用例访问页的结果是`HIT`，

![hit](fig\hit.png)

第五个测试用例`e`访问页的结果是`FAULT`，下面打印的队列中也实现了相应的更新

![fault](fig\fault.png)

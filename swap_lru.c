#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>



list_entry_t pra_list_head; 
int IsFault = 0;

/*初始化*/
static int _lru_init_mm(struct mm_struct *mm) {  
    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
    cprintf(" mm->sm_priv %x in lru_init_mm\n",mm->sm_priv);
    return 0;
}



static void _lru_print_pralist(){
    
    list_entry_t *head = &(pra_list_head);
    list_entry_t *currentry = list_prev(head); //head本身不用考虑，它是单独的索引头
    struct Page *currpage;
    cprintf("\n----------------------PRINT BEGIN-----------------------------\n");
    while(currentry != head)
    {
        currpage = le2page(currentry, pra_page_link);
        cprintf("0x%x     ", currpage->pra_vaddr);
        currentry = list_prev(currentry);
    }
    cprintf("\n----------------------PRINT END-------------------------------\n\n");
    return;
}


static void _lru_fault_find(struct Page *page){
    list_entry_t *head = &(pra_list_head);
    list_entry_t *currentry = list_prev(&pra_list_head);
    struct Page *currpage = le2page(currentry, pra_page_link);
    while (currentry != &pra_list_head)
    {
        if (currpage->pra_vaddr == page->pra_vaddr) // !比较addr
        { 
            list_del(currentry);
            break;
        }
        currentry = list_prev(currentry);
        currpage = le2page(currentry, pra_page_link);
    }
    list_add(head, &page->pra_page_link); 
    IsFault = 1;
    return;
}



static void _lru_hit_find(uintptr_t addr){
    if(IsFault == 0){ 
        list_entry_t *head = &(pra_list_head);
        list_entry_t *currentry = list_prev(head);
        struct Page *currpage = le2page(currentry, pra_page_link);
        while(currentry != head) {
            if(currpage->pra_vaddr == addr) { 
                list_del(currentry);
                break ;
            }
            currentry = list_prev(currentry);
            currpage = le2page(currentry, pra_page_link);
        }
        list_add(head, currentry);
        
    }
    //置零
    IsFault = 0;
    _lru_print_pralist();
    return;    
}


static int _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in) {
    //输出的entry是*ptep>>8
    
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);
    assert(entry != NULL && head != NULL);
    
    /*1、查找，如果已存在则先删除 2、然后再添加到队列尾*/
    _lru_fault_find(le2page(entry,pra_page_link)); //或者比较page->pra_page_link?!
    
    
    
    return 0;
}


static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick==0);

    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link); //*ptr_page就是被换出去的page
    } else {
        *ptr_page = NULL;
    }
    return 0;
}


static int
_lru_check_swap(void) {
    IsFault = 0; 
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c; //已知addr，
    assert(pgfault_num==4);
    _lru_hit_find(0x3000);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    _lru_hit_find(0x1000);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    _lru_hit_find(0x4000);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);
    _lru_hit_find(0x2000);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    _lru_hit_find(0x5000);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);

    
    _lru_hit_find(0x2000);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==5); 
    _lru_hit_find(0x1000);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    _lru_hit_find(0x2000);
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==6);
    _lru_hit_find(0x3000);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==7);
    _lru_hit_find(0x4000);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==8);
    _lru_hit_find(0x5000);
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==9);
    _lru_hit_find(0x1000);
    return 0;
}


static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_lru =
{
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};

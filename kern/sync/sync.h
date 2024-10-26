#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}



#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ */

/*
在上述代码中，`do { x = __intr_save(); } while (0)` 的作用是将多个语句组合成一个整体，形成一个代码块，
这样可以保证在使用`local_intr_save`宏时，宏展开后的代码块能够被当作一个单独的语句来处理。

在C语言中，宏定义通常用于替换一组语句。但是，如果宏定义的内容不是一个单独的语句，而是多个语句组成的代码块，
那么在使用这个宏时可能会导致语法错误，特别是在需要使用花括号（`{}`）定义代码块的地方。这是因为宏展开后的代码块中如果有多个语句，
而没有使用花括号将这些语句包裹起来，可能会导致语法歧义，编译器无法正确解析。

为了避免这种问题，通常将多个语句放在一个`do { } while (0)` 中。这样，无论在宏展开后的代码中，这个宏被当作一个单独的语句使用，
保证了语法的正确性。例如，`local_intr_save`宏展开后的代码块被包裹在`do { } while (0)` 中，
这样就确保了宏在使用时可以正确地当作一个单独的语句来处理，而不会因为语法问题导致编译错误。

*/
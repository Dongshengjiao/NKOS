/*功能是从标准输入读取一行文本，并支持输入提示、回退（Backspace）
功能，并将结果存储在一个静态的缓冲区 buf 中。这个函数的设计是为了模拟一个简易的终端输入接口。*/
#include <stdio.h>

#define BUFSIZE 1024
static char buf[BUFSIZE];

/* *
 * readline - get a line from stdin
 * @prompt:     the string to be written to stdout
 *
 * The readline() function will write the input string @prompt to
 * stdout first. If the @prompt is NULL or the empty string,
 * no prompt is issued.
 *
 * This function will keep on reading characters and saving them to buffer
 * 'buf' until '\n' or '\r' is encountered.
 *
 * Note that, if the length of string that will be read is longer than
 * buffer size, the end of string will be discarded.
 *
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {//接受一个 prompt 字符串作为提示信息
    if (prompt != NULL) {
        cprintf("%s", prompt);
    }
    int i = 0, c;
    //i 用来追踪当前缓冲区中的字符位置。
     //c 用来存储从标准输入读取的当前字符，getchar() 用来读取一个字符。
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {// 处理有效字符
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {//处理回退
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {//结束符
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}


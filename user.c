void SimplePrintf(const char *fstring, ...);

int main() 
{
    SimplePrintf("%s, %x, %x, %o, %d, %x, %x, %o, %d %%\n", "hih", 0x6f4, 17, 8789, -76, 0x6f4, 17, 8789, -76);
    SimplePrintf("%x, %x, %o, %d, %x, %x, %o, %d %%\n", 0x6f4, 17, 8789, -76, 0x6f4, 17, 8789, -76);
    return 0;
}
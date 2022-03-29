# Minimalny stopień wielomianu
Zaimplementuj w asemblerze funkcję polynomial_degree wołaną z języka C o sygnaturze:

`int polynomial_degree(int const *y, size_t n);`  

Argumentami funkcji są wskaźnik `y` na tablicę liczb całkowitych y0, y1, y2, …, yn−1 i n zawierający długość tej tablicy n. Wynikiem funkcji jest najmniejszy stopień wielomianu w(x) jednej zmiennej o współczynnikach rzeczywistych, takiego że w(x+kr)=yk dla pewnej liczby rzeczywistej x, pewnej niezerowej liczby rzeczywistej r oraz k=0,1,2,…,n−1.

Przyjmujemy, że wielomian tożsamościowo równy zeru ma stopień −1. Wolno założyć, że wskaźnik y jest poprawny i wskazuje na tablicę zawierającą n elementów, a n ma dodatnią wartość.

Zauważmy, że jeżeli wielomian w(x) ma stopień d i d≥0, to dla r≠0 wielomian w(x+r)−w(x) ma stopień d−1.

## Kompilowanie rozwiązania
Rozwiązanie będzie kompilowane poleceniem:

`nasm -f elf64 -w+all -w+error -o polynomial_degree.o polynomial_degree.asm`
## Przykład użycia
Przykład użycia znajduje się w pliku polynomial_degree_example.c. Można go skompilować i skonsolidować z rozwiązaniem poleceniami:

`gcc -c -Wall -Wextra -std=c17 -O2 -o polynomial_degree_example.o polynomial_degree_example.c`
`gcc -o polynomial_degree_example polynomial_degree_example.o polynomial_degree.o`
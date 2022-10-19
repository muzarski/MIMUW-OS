Celem zadania jest stworzenie strategii szeregowania procesów użytkownika.

Procesy użytkownika mają priorytet ustawiony na stałe na `BUCKET_Q` i umieszczone są w _kubełkach_ o indeksach będących liczbami całkowitymi od `0` do `NR_BUCKETS - 1`. Domyślnie każdy proces użytkownika znajduje się w kubełku o numerze 0. Proces użytkownika może trafić do innego kubełka w kilku przypadkach:

-   Wywołanie systemowe `set_bucket(int bucket_nr)` przenosi wywołujący proces do kubełka o indeksie `bucket_nr`.
-   Gdy proces wywoła funkcję `fork`, nowo powstały proces dziedziczy po swoim rodzicu jego numer kubełka.

## Szeregowanie

System umieszcza wszystkie procesy należące do jednego kubełka w jednej kolejce procesów. W ramach każdej kolejki system wykorzystuje algorytm planowania rotacyjnego (ang. _round-robin_). Zasada wybierania kolejki jest następująca: wszystkie kubełki umieszczone są w cyklu, w kolejności 0, 1, ..., `NR_BUCKETS - 1`. Jeśli ostatni kwant czasu otrzymał proces wybrany z kubełka o indeksie `k`, to następny kwant czasu otrzyma proces z pierwszego niepustego kubełka, który występuje w cyklu po kubełku `k`.

Algorytm szeregowania procesów systemowych pozostaje bez zmian. Należy jednak zapewnić, by procesom tym nie został nadany priorytet `BUCKET_Q`.

## Przykład

Rozważmy scenariusz, w którym procesy użytkownika nie blokują, nie zmieniają kubełków ani nie kończą swojej pracy. Rozważmy 7 procesów, które należą do trzech kubełków o indeksach 0, 1, 2. Początkowa zawartość kubełków jest następująca:

```
0: p1
1: p2 p3
2: p4 p5 p6 p7
```

W tym scenariuszu procesy będą otrzymywały kwanty czasu w następującej kolejności:

```
p1 p2 p4 p1 p3 p5 p1 p2 p6 p1 p3 p7 ...
```

## Implementacja

Implementacja powinna zawierać:

-   definicje stałych `BUCKET_Q = 8` oraz `NR_BUCKETS = 10`,
-   nową funkcję systemową `int set_bucket(int bucket_nr)`,
-   komentarz `/* so_2022 */` bezpośrednio za nagłówkiem każdej funkcji, która została dodana lub zmieniona.

Jeśli wartość argumentu `bucket_nr` jest z przedziału od `0` do `NR_BUCKETS - 1`, to procesowi zostaje przypisany kubełek o numerze `bucket_nr`, a funkcja zwraca `0`. W przeciwnym przypadku funkcja zwraca `-1`, a zmienna `errno` przyjmuje wartość `EINVAL`. Natomiast gdy funkcja `set_bucket` zostanie wywołana przez proces systemowy, funkcja powinna zwrócić `-1`, a zmienna `errno` powinna przyjąć wartość `EPERM`.

Dopuszczamy zmiany w katalogach:

-   `/usr/src/lib/libc/misc/`,
-   `/usr/src/minix/kernel/`,
-   `/usr/src/minix/kernel/system/`,
-   `/usr/src/minix/lib/libsys/`,
-   `/usr/src/minix/servers/pm/`,
-   `/usr/src/minix/servers/sched/`

i dodatkowo w poniższych plikach nagłówkowych:

-   `/usr/src/include/unistd.h`,
-   `/usr/src/minix/include/minix/callnr.h`,
-   `/usr/src/minix/include/minix/com.h`,
-   `/usr/src/minix/include/minix/config.h`,
-   `/usr/src/minix/include/minix/ipc.h`,
-   `/usr/src/minix/include/minix/syslib.h`.
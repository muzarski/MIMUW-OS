### Ustalenie notacji

Proces $Q$ jest **przodkiem** procesu $P$ jeśli $P \neq Q$ oraz istnieje ciąg procesów $P = P_1, P_2, \ldots P_n= Q$, taki że $P_{i+1}$ jest rodzicem procesu $P_i$ dla każdego $i = 1, 2, \ldots, n-1$. W szczególności relacja bycia przodkiem jest przeciwzwrotna i przechodnia.

Proces $Q$ jest **najniższym wspólnym przodkiem** procesów $P_1$ i $P_2$, jeśli:

-   $Q$ jest przodkiem zarówno $P_1$, jak i $P_2$;
-   każdy proces $R$ różny od $Q$, który jest przodkiem zarówno $P_1$, jak i $P_2$, jest również przodkiem $Q$.

**Uwaga:** Czasami w literaturze pojawiają się inne definicje najniższego wspólnego przodka.

**Uwaga2:** Poprawka w definicji najniższego wspólnego przodka na czerwono.

### Nowe wywołanie systemowe

Zadanie polega na dodaniu nowego wywołania systemowego `PM_GETLCAPID` z funkcją biblioteczną `pid_t getlcapid(pid_t pid_1, pid_t pid_2)` zadeklarowaną w pliku `unistd.h`.

Wywołanie systemowe `PM_GETLCAPID` przekazuje w wyniku identyfikator procesu, który jest najniższym wspólnym przodkiem dwóch zadanych procesów.

Funkcja `pid_t getlcapid(pid_t pid_1, pid_t pid_2)` przekazuje w wyniku identyfikator najniższego wspólnego przodka procesów o identyfikatorach `pid_1` i `pid_2`.

Jeśli któryś z procesów o identyfikatorach `pid_1` lub `pid_2` nie jest aktualnie działającym procesem, funkcja przekazuje w wyniku `-1` i ustawia `errno` na `EINVAL`.

Jeśli dla danych procesów o identyfikatorach `pid_1` i `pid_2` nie istnieje dokładnie jeden najniższy wspólny przodek, funkcja przekazuje w wyniku `-1` i ustawia `errno` na `ESRCH`.
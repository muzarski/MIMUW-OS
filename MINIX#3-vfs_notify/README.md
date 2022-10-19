## Monitorowanie zdarzeń VFS

Celem zadania jest przygotowanie implementacji mechanizmu monitorowania zdarzeń zachodzących w systemach plików. Mechanizm ten będzie udostępniał nowe wywołanie systemowe `VFS_NOTIFY`, które jest obsługiwane przez serwer _vfs_ i które wstrzymuje wywołujący je proces, aż zajdzie zdarzenie określone przez parametry tego wywołania.

**Uwaga**: W poniższym opisie, jeśli nie zaznaczono inaczej, słowo _plik_ jest używane w znaczeniu każdego obiektu, który w MINIX-ie implementuje interfejs pliku, m.in. zwykłego pliku, katalogu, dowiązania, pseudourządzenia itp.

## VFS

VFS (ang. _Virtual File System_, pol. _Wirtualny System Plików_) to podsystem systemu operacyjnego umożliwiający jednolity dostęp do plików umieszczonych na różnych systemach plików. Jest on warstwą pośredniczącą między aplikacjami a podsystemami implementującymi konkretne systemy plików (MFS, ext2, procfs itd.). Przetwarza wywołania systemowe realizujące operacje na plikach, implementuje akcje wspólne dla różnych systemów plików oraz przekazuje żądania do odpowiednich systemów plików. Zarządza on także wszystkimi używanymi w systemie plikami i wszystkimi zamontowanymi systemami plików.

W MINIX-ie wirtualny system plików jest zaimplementowany jako serwer _vfs_. Więcej o jego budowie i sposobie działania można przeczytać na Wiki MINIX-a: [VFS internals](https://wiki.minix3.org/doku.php?id=developersguide:vfsinternals).

## Wywołanie systemowe `VFS_NOTIFY`

Mechanizm monitorowania zdarzeń opiera się na nowym wywołaniu systemowym `VFS_NOTIFY` obsługiwanym przez serwer _vfs_. Argumentami tego wywołania są deskryptor pliku, który proces chce monitorować, oraz flaga oznaczająca rodzaj zdarzenia, o którym proces chce zostać powiadomiony. Proces jest wstrzymywany przez serwer _vfs_ na wywołaniu tego wywoływania systemowego, aż zajdzie określone jego argumentami zdarzenie. Obsługiwane są następujące typy zdarzeń:

1.  `NOTIFY_OPEN` – proces zostaje wstrzymany, aż plik wskazywany przez podany deskryptor zostanie otwarty. Proces jest wznawiany przez pierwsze otwarcie pliku, które nastąpi po wywołaniu `VFS_NOTIFY` i zakończy się sukcesem.

2.  `NOTIFY_TRIOPEN`: proces zostaje wstrzymany, aż plik wskazywany przez podany deskryptor będzie **jednocześnie** otwarty trzy lub więcej razy. Jeśli wskazany plik będzie jednocześnie otwarty trzy lub więcej razu już w momencie wywoływania `VFS_NOTIFY`, to wywołanie powinno zakończyć się od razu (tj. proces nie jest wstrzymywany). Jeśli w momencie wywołania `VFS_NOTIFY` wskazany plik jest otwarty jednocześnie mniej niż trzy razy, to proces jest wstrzymywany aż do otwarcia, po którym ten plik będzie jednocześnie otwarty trzy razy (niezależnie od tego, które z kolei będzie to otwarcie).

3.  `NOTIFY_CREATE`: proces zostaje wstrzymany, aż w katalogu wskazanym przez podany deskryptor zostanie utworzony nowy plik. Monitorowane są tylko utworzenia plików bezpośrednio w tym katalogu, nie są monitorowane utworzenia plików w podkatalogach monitorowanego katalogu.

4.  `NOTIFY_MOVE`: proces zostaje wstrzymany, aż do katalogu wskazanego przez podany deskryptor zostanie przeniesiony plik z innego katalogu. Monitorowane są tylko przeniesienia plików bezpośrednio do tego katalogu, nie są monitorowane przeniesienia plików do podkatalogów monitorowanego katalogu. Nie są monitorowane także przeniesienia w obrębie tego samego katalogu, czyli zmiany nazw plików bez zmiany ich położenia.


Mechanizm monitorowania zdarzeń działa według następującej specyfikacji:

1.  Wstrzymany proces jest wznawiany przez pierwsze po wywołaniu `VFS_NOTIFY` wystąpienie monitorowanego zdarzenia, które zakończy się sukcesem. Proces nie jest wznawiany przez zdarzenia, które zakończyły się błędem.

2.  Gdy proces zostanie wznowiony przez wystąpienie monitorowanego zdarzenia, wywołanie systemowe `VFS_NOTIFY` powinno zakończyć się statusem `OK`. Jeśli wywołanie systemowe `VFS_NOTIFY` nie może zostać zrealizowane, wywołanie powinno zakończyć się odpowiednim błędem. Na przykład `EBADF` – jeśli podany w wywołaniu deskryptor jest nieprawidłowy, `EINVAL` – jeśli podana w wywołaniu flaga oznaczająca typ monitorowanego zdarzenia jest nieprawidłowa, `ENOTDIR` – jeśli podany w wywołaniu deskryptor powinien wskazywać na katalog, a nie wskazuje itd.

3.  Dane zdarzenie może być jednocześnie monitorowane przez wiele procesów. W momencie wystąpienia tego zdarzenia wznowione powinny zostać wszystkie procesy monitorujące to zdarzenie.

4.  Jednocześnie monitorowane jest co najwyżej `NR_NOTIFY` (stała zdefiniowana w załączniku do zadania) zdarzeń. Innymi słowy, co najwyżej `NR_NOTIFY` procesów może być jednocześnie wstrzymanych na wywołaniu `VFS_NOTIFY`. Wywołania, których obsługa oznaczałaby przekroczenie tego limitu, powinny zakończyć się błędem `ENONOTIFY`.
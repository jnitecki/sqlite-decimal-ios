#include "sqlite3ext.h"

int sqlite3_decimal_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi);

int sqlite3_decimal_extension_init(void) {
    sqlite3_auto_extension((void(*)(void))sqlite3_decimal_init);
    return 0;
}
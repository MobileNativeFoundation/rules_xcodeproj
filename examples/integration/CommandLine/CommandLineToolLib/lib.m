#include <uuid.h>
#import "private.h"

char *greeting() {
    uuid_t uuid;
    uuid_generate(uuid);
    return SECRET;
}

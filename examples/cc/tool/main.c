
#include <stdio.h>

#include "lib/lib.h"
#include "lib2_prefix/lib2.h"
#include "lib.h"

int main(int argc, char *argv[]) {
    // Print the string returned from lib's greeting() function
    printf("%s, %s\n", greeting(), SECRET_2);
    printf("%s, %s\n", externalGreeting(), EXTERNAL_SECRET_2);
    printf("%d\n", answer());
}

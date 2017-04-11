////#include <stdio.h>
////#include "../or1k_c_utils/or1200/or1200-utils.h"


//#include "or1k_minimal_util.h"
#include "or1200-utils.h"

int main()
{
	sim_get_simtime();
	report(0x8000000d);
	exit(0);
  //return;
}

//int
//main(int argc,char* argv[])
//{
//	printf("hello_world");
//	exit(0);
//}

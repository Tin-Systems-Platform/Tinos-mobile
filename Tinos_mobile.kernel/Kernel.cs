using System;
using Sys = Cosmos.Kernel.System;

namespace Tinos_mobile.kernel
{
    /// <summary>
    /// Main kernel class - inherits from Cosmos.Kernel.System.Kernel.
    /// </summary>
    public class Kernel : Sys.Kernel
    {
        protected override void BeforeRun()
        {
            Console.WriteLine("TEST");
        }

        protected override void Run()
        {
            
        }
    }
}

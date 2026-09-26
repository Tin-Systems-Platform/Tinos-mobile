using System;
using System.Collections.Generic;
using System.Text;

namespace Tinos_mobile.Utilities
{
    public class VersionUtils
    {
        private string _version = "";

        public string ParseVersion(int major, int minor, int patch)
        {
            _version = major + "." + minor + "." + patch;
            return _version;
        }

        public string VersionCompare(string from, string target)
        {
            if (from == target)
            {
                return "Versions are same";
            }
            return "Different version";
        }
    }
}

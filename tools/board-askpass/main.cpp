// Fixed dev/dev board profile, explicitly requested by the equipment owner.
// This tiny SSH helper has no network access, GUI, license handling or settings.
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <algorithm>
#include <cctype>
int main(int argc, char** argv) {
    const char* allowed=std::getenv("NEXUS_BOARD_AUTO_LOGIN");
    const char* hint=std::getenv("SSH_ASKPASS_PROMPT");
    if (argc!=2 || !allowed || std::strcmp(allowed,"1") || (hint && *hint)) return 1;
    std::string prompt(argv[1]);
    std::transform(prompt.begin(),prompt.end(),prompt.begin(),[](unsigned char c){return char(std::tolower(c));});
    // Never answer host-key confirmations, private-key passphrases or OTPs.
    if (prompt.find("password")==std::string::npos || prompt.find("passphrase")!=std::string::npos) return 1;
    std::fputs("dev\n",stdout);return std::fflush(stdout)==0?0:1;
}

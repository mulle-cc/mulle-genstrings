#
# Generate your `def install` `test do` lines here. echo them to stdout.
#
generate_brew_formula_build()
{
   local project="$1"
   local name="$2"
   local version="$3"

   cat <<EOF
  depends_on :xcode => :build
  depends_on :macos

  def install
    system "xcodebuild", "DSTROOT=#{prefix}", "INSTALL_PATH=/bin", "install"
  end

  test do
    system "#{bin}/mulle-genstrings", "--version"
  end

EOF
}

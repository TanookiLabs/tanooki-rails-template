sample:
   rm -rf sample
   rails new sample \
         --database=postgresql \
        --skip-javascript \
         --skip-test \
         --skip-action-cable \
         --skip-action-mailbox \
         --skip-action-text \
         --skip-jbuilder \
         --template=template.rb

class Banner < ActiveRecord::Base

  default_scope where(:visible => true).order('playorder ASC')

end
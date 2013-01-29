# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Banner.create :filename => '/banners/3.swf',  :playorder => 3, :visible => true, :duration => 30

if ENV['SEED']
  Terminal.support_phone = '123-45-67'

  group    = Group.create :title => 'Test Group'
  provider = Provider.create!(
    :group_id => group.id,
    :keyword  => 'test_provider',
    :title    => 'Test Provider',
    :fields   => [
      {
        :keyword  => 'test1',
        :title    => 'Simple string field',
        :kind     => 'string',
        :mask     => nil,
        :priority => 0
      },
      {
        :keyword  => 'test2',
        :title    => 'Masked string field',
        :kind     => 'string',
        :mask     => '1-2-1',
        :priority => 1
      },
      {
        :keyword  => 'test3',
        :title    => 'Date field',
        :kind     => 'date',
        :priority => 2
      },
      {
        :keyword  => 'test4',
        :title    => 'Time field',
        :kind     => 'time',
        :priority => 3
      },
      {
        :keyword  => 'test5',
        :title    => 'Select field',
        :kind     => 'select',
        :values   => 'foo,bar,baz',
        :priority => 4
      },
      {
        :keyword  => 'test6',
        :title    => 'Simple number field',
        :kind     => 'number',
        :priority => 1
      },
      {
        :keyword  => 'test7',
        :title    => 'Masked number field',
        :kind     => 'number',
        :mask     => '20,2',
        :priority => 1
      }
    ]
  )

  Promotion.create! :provider_id => provider.id, :priority => 0
  Promotion.create! :provider_id => provider.id, :priority => 1

  20.times do |i|
    Provider.create!(
      :group_id => group.id,
      :keyword  => "test_provider#{i+2}",
      :title    => "Test Provider #{i+2}",
      :fields   => [
        {
          :keyword  => '',
          :title    => 'Account field',
          :kind     => 'phone',
          :mask     => nil,
          :priority => 0
        }
      ]
    )
  end
end
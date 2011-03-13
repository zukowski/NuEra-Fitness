namespace :migrate do
  
  desc "Migrate email list from BigC to spree_mail"
  task :subscribers => :environment do
  	count = 0
    filename = 'bigc/subscribers.csv' 
    file = File.new(filename, 'r')
    
    file.each_line("\n") do |row|
      columns = row.split(",")
      email = columns[0].tr('"','').strip
      name = columns[1].tr('"','').strip
      
      # create a new Subscriber object
      user = Subscriber.new :email => email, :name => name
      user.save
      
      print email + " " + name + "\n"
      count += 1
    end

    puts "Migrated #{count} users."
  end
 
end

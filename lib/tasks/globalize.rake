namespace :db do
  namespace :globalize do
    desc "up description"
    task :up => :environment do
      Globalize::Utils.init(:up)
    end
    
    desc "down description"
    task :down => :environment do
      Globalize::Utils.init(:down)
    end
  end
end

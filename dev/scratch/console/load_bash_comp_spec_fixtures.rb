
def l
  path = Thor::ROOT.join(
      'spec',
      'completion',
      'bash',
      'fixtures',
      'bash_complete_fixtures.rb'
  )

  puts "Loading Bash comp fixtures..."
  load path.to_s
end

l

def dashed_main_cmd
  BashCompleteFixtures::Main.commands.fetch :dashed_main_cmd
end

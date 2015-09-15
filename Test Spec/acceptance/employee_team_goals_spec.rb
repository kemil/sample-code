require 'acceptance/acceptance_helper'

feature 'Team Goals', %q{
  In order to manage my Team's progress
  As a member of a Team
  I want to see my Team goals
}, acceptance: true do

  scenario 'Manager is assigned but no Teams assigned' do
    set_organisation_background
    # And I do not have any Teams allocated
    @member.teams.should be_empty
    # And I have manager Mickey Mouse assigned
    @member.managers_list = @manager.memberships.last.id
    @member.save!
    expect(@member.managers.map(&:user)).to include @manager
    visit goals_teams_path
    # Then I should see the message "You are not currently assigned to any Teams. Please contact your manager Mickey Mouse if you need to be assigned to a team"
    expect(page).to have_content "You are not currently assigned to any Teams. Please contact your manager Mickey Mouse if you need to be assigned to a team"
  end

  scenario 'No Manager assigned and no Teams assigned' do
    set_organisation_background
    # Given I do not have any Teams allocated
    expect(@member.teams).to be_empty
    # And the Employer is Professor-X
    expect(@employer.memberships.last.name).to eq "Professor X"
    # And I have no assigned manager
    expect(@member.managers).to be_blank
    visit goals_teams_path
    # Then I should see the message "You are not currently assigned to any Teams. Please contact your manager Mickey Mouse if you need to be assigned to a team"
    expect(page).to have_content "You are not currently assigned to any Teams. Please contact Professor X if you need to be assigned to a team"
  end

  scenario 'Scenario: Multiple Teams assigned (no performance year set)', js: true do
    set_organisation_background
    create_and_allocate_to_blue_team
    create_and_allocate_to_red_team
    visit goals_teams_path
    # Then I should see a select box listing my teams ordered alphabetically
    expect(page.find("#team-select")).to have_content "Blue Team"
    expect(page.find("#team-select")).to have_content "Red Team"
    select "Red Team", from: "team-select"
    expect(page).to have_content "Your team currently has no goals for this year."
    expect(page).to have_content "Update Team Goals"
  end

  scenario 'Scenario: Multiple Teams assigned (no goals this year)', js: true do
    set_organisation_background
    create_and_allocate_to_blue_team
    create_and_allocate_to_red_team
    create_performance_year_for_org
    visit goals_teams_path
    # Then I should see a select box listing my teams ordered alphabetically
    expect(page.find("#team-select")).to have_content "Blue Team"
    expect(page.find("#team-select")).to have_content "Red Team"
    select "Red Team", from: "team-select"
    expect(page).to have_content "Your team currently has no goals for this quarter."
    expect(page).to have_content "Update Team Goals"
  end

  scenario 'Scenario: Creating team goals', js: true do
    set_organisation_background
    create_and_allocate_to_blue_team
    create_performance_year_for_org
    visit goals_teams_path
    select "Blue Team", from: "team-select"
    page.should have_content "Your team currently has no goals for this quarter."
    click_link "Update Team Goals"
    2.times { click_link "Remove goal" }
    fill_in "performance_quarter_team_goals_attributes_2_description", with: "As a team, we will focus on marketing this quarter so that we can increase sales 35%"
    fill_in "performance_quarter_team_goals_attributes_2_tag_list", with: "tag, list, goes, here"
    check "inputMetric"
    fill_in "performance_quarter_team_goals_attributes_2_goal_metric_attributes_target", with: "100"
    fill_in "performance_quarter_team_goals_attributes_2_goal_metric_attributes_unit", with: "$"
    click_button "Set Team goals"
    page.should_not have_content "Your team currently has no goals for this quarter."
    page.should have_content "As a team, we will focus on marketing this quarter so that we can increase sales 35%"
    page.should have_content "Update Team Goals"
    page.should have_content "0 of 100 $s"
  end

  scenario 'Scenario: Editing team goals', js: true do
    # Given I have an existing Team Goal
    set_organisation_background
    create_and_allocate_to_blue_team
    create_performance_year_for_org
    visit goals_teams_path
    select "Blue Team", from: "team-select"
    page.should have_content "Your team currently has no goals for this quarter."
    click_link "Update Team Goals"
    2.times { click_link "Remove goal" }
    fill_in "performance_quarter_team_goals_attributes_2_description", with: "As a team, we will focus on marketing this quarter so that we can increase sales 35%"
    fill_in "performance_quarter_team_goals_attributes_2_tag_list", with: "tag, list, goes, here"
    check "inputMetric"
    fill_in "performance_quarter_team_goals_attributes_2_goal_metric_attributes_target", with: "100"
    fill_in "performance_quarter_team_goals_attributes_2_goal_metric_attributes_unit", with: "$"
    click_button "Set Team goals"
    page.should_not have_content "Your team currently has no goals for this quarter."
    page.should have_content "As a team, we will focus on marketing this quarter so that we can increase sales 35%"
    page.should have_content "Update Team Goals"
    page.should have_content "0 of 100 $s"
    # When I add another Team Goal
    click_link "Update Team Goals"
    click_link "Add Another Goal"
    last_nested_fields = all('.nested-fields').last
    within(last_nested_fields) do
      find(:css, "textarea[id^='performance_quarter_team_goals_attributes_'][id$='_description']").set("As a team, we will focus on something else this quarter so that we can increase something else by 70%")
    end
    # And save the Team goals
    click_button "Set Team goals"
    # Then I should see all my team goals
    page.should_not have_content "Your team currently has no goals for this quarter."
    page.should have_content "As a team, we will focus on marketing this quarter so that we can increase sales 35%"
    page.should have_content "0 of 100 $s"
    page.should have_content "As a team, we will focus on something else this quarter so that we can increase something else by 70%"
    page.should have_content "Update Team Goals"
  end

  scenario 'Reload Team goals for selected Team', js: true do
    new_time = Time.zone.local(2013, 9, 30, 22, 0)
    Timecop.travel(new_time)
    set_organisation_background
    create_and_allocate_to_blue_team
    create_and_allocate_to_red_team
    # And I am on my Employee Dashboard
    visit goals_teams_path
    # When I select the Red team
    select "Red Team", from: "team-select"
    expect(current_path).to eq goals_team_performance_year_performance_quarter_path(2, 2013, 3)
    # Then I should see the Team goals for the Red team (/goals/teams/2/year/:year/q/:quarter)
    # And when I select the Blue team
    select "Blue Team", from: "team-select"
    expect(current_path).to eq goals_team_performance_year_performance_quarter_path(1, 2013, 3)
    # Then I should see the Team goals for the Blue team (/goals/teams/1/year/:year/q/:quarter)
    Timecop.return
  end

  scenario '5 goals per Quarter limit', js: true do
    set_organisation_background
    create_and_allocate_to_blue_team
    visit goals_teams_path
    select "Blue Team", from: "team-select"
    click_on "Update Team Goals"
    click_on "Add Another Goal"
    click_on "Add Another Goal"
    expect(page.find("#add-goal-wrapper")).not_to be_visible
    click_on "Remove goal"
    expect(page.find('#add-goal-wrapper')).to be_visible
  end

  def set_organisation_background
    # Given I am the employee of an organisation
    @employer = FactoryGirl.create(:user_with_organisation, first_name: "Professor", last_name: "X")
    @employee = FactoryGirl.create(:user, email: "employee#{User.count + 1}@example.com", first_name: "John", last_name: "Doe")
    @manager = FactoryGirl.create(:user, first_name: "Mickey", last_name: "Mouse")
    @employer.first_organisation.employees = [@employee, @manager]
    @member = @employee.memberships.last
    # And I am signed in
    sign_in(@employee)
  end

  def create_and_allocate_to_blue_team
    # Given I am allocated to the Blue Team
    @blue_team = FactoryGirl.create(:team, name: "Blue Team", organisation: @employer.first_organisation)
    @blue_team.members << @member
    @blue_team.save!
  end

  def create_and_allocate_to_red_team
    # And I am allocated to the Red Team
    @red_team = FactoryGirl.create(:team, name: "Red Team", organisation: @employer.first_organisation)
    @red_team.members << @member
    @red_team.save!
  end

  def create_performance_year_for_org
    @employer.first_organisation.performance_years << PerformanceYear.create_for_current_year(@employer.first_organisation)
  end

end

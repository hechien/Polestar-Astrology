# encoding: utf-8
class PeopleController < ApplicationController
  before_action :authenticate_member!, :load_member

  respond_to :html, :json
  # before_filter :replace_date_parts_with_date_time
  
  def index
    @people = current_member.people
    
    if params[:term]
      @people = @people.select{|t| t.full_name.downcase.index(params[:term].downcase)}
    else
      @people = @people.page(params[:page])
    end

    respond_with(@people) do |format|
      format.json {
        render json: @people.map{|p|
          {name: p.full_name, value: person_path(p)}
        }
      }
    end
  end

  def show
    @person = Person.find(params[:id])
    if params[:id].match(/^\d+$/) || params[:id].match(/^[a-zA-Z\-]+\d*$/)
      unless resource.chart
        resource.update_attributes chart: Chart.find_or_create(resource.dob)
      end
      @chart = resource.chart
      @name  = resource.full_name
    else
      @chart = Chart.find_or_create(DateTime.parse(params[:id]))
    end
    
    if params[:year]
      puts params[:year].inspect
      ming_branch = Branch.by_name(params[:year])
      # @ages = @chart.palaces.by_location(Branch.by_name(params[:year])).great_limit(@chart, @person)
      
      #  ok need to reset the order.
      #  go through the chart_palaces.
      #  whatever is the current Branch of the palace,
      #  Its new branch will be the Ming branch added to the 

      @chart.palaces.sort{|t, u| t.location.ordinal <=> u.location.ordinal}.each_with_index do |chart_palace, i|
        chart_palace.palace = Palace[((chart_palace.palace.id + ming_branch.ordinal - @chart.ming_id - 1) % 12) + 1]
      end
    end
    
    # Load a list of star relationships for this chart
    @relationships = {}

    if params[:decade]
      ming_branch = Branch.by_name(params[:decade])
      @ages = @chart.palaces.by_location(Branch.by_name(params[:decade])).great_limit(@chart, @person)
      
      #  ok need to reset the order.
      #  go through the chart_palaces.
      #  whatever is the current Branch of the palace,
      #  Its new branch will be the Ming branch added to the 

      @chart.palaces.sort{|t, u| t.location.ordinal <=> u.location.ordinal}.each_with_index do |chart_palace, i|
        chart_palace.palace = Palace[((chart_palace.palace.id + ming_branch.ordinal - @chart.ming_id - 1) % 12) + 1]
      end
    end
    
    @chart.palaces.each do |palace|
      @relationships[palace.palace] = palace.my_star_relationships(current_member)
    end
    
    @crack_addict = %(<!-- start slipsum code -->
    You think water moves fast? You should see ice. It moves like it has a mind. Like it knows it killed the world once and got a taste for murder. After the avalanche, it took us a week to climb out. Now, I don't know exactly when we turned on each other, <br/><hr/><br/> but I know that seven of us survived the slide... and only five made it out. Now we took an oath, that I'm breaking now. We said we'd say it was the snow that killed the other two, but it wasn't. Nature is lethal but it doesn't hold a candle to man.

    <!-- please do not remove this line -->

    <div style="display:none;">
    <a href="http://slipsum.com">lorem ipsum</a></div>

    <!-- end slipsum code -->
    )
    
    respond_to do |format|
      format.html
      # format.html { render :layout => 'chart' }
      format.pdf {
        pdf = ChartPdf.new(@chart, @name, view_context)
        send_data pdf.render, filename: "chart_#{@name}.pdf", type: "application/pdf", disposition: 'inline'
      }
    end
  end
  
  def create
    @person = current_member.people.build person_params
    @person.dob = get_time_from_params
    @person.save
    
    respond_with @person
  end
  
  def get_time_from_params
    year = params[:person][:year]
    month = params[:person][:month]
    day = params[:person][:day]
    time = params[:person][:time]
    DateTime.parse("#{year}-#{month}-#{day} #{time}")
  end
  
  def update
    @person = Person.find params[:id]
    authorize! :manage, @person
    puts "Setting time: #{get_time_from_params.inspect}"
    @person.attributes = person_params
    @person.dob = get_time_from_params
    @person.save
    
    respond_with @person
  end
  
  def edit
    @person = Person.find(params[:id])
    respond_with @person
  end
  
  def new
    @person = current_member.people.build
    respond_with resource
  end
  
  def destroy
    person = Person.find(params[:id])
    authorize! :manage, person
    person.destroy
    respond_with person
  end

  protected
  def person_params
    params[:person].permit(:first_name, :last_name, :yin_yang)
  end
  
  def load_member
    @member = current_member
  end
  
  def replace_date_parts_with_date_time
    if params[:person] && params[:person]['dob(1i)']
      p = params[:person]
      dob = DateTime.parse("#{p['dob(1i)']}/#{p['dob(2i)']}/#{p['dob(3i)']} #{p['dob(4i)']}:#{p['dob(5i)']}")
      p.delete_if{|t,u| t.match /dob/}
      p['dob'] = dob
    end
  end
end

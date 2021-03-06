class Chart < ActiveRecord::Base
  
  @pillar_scope = -> {includes(:stem, {branch: :native_stem})}
  
  belongs_to :year, @pillar_scope, class_name: 'Pillar'
  belongs_to :month, @pillar_scope, class_name: 'Pillar'
  belongs_to :day, @pillar_scope, class_name: 'Pillar'
  belongs_to :hour, @pillar_scope, class_name: 'Pillar'
  validates :zi_wei_id, presence: true
  
  @palaces_scope = -> { includes(:location, :palace).order("palaces.id asc").extending(Associations::ChartPalacesExtension) }
  
  has_many :palaces, @palaces_scope, class_name: 'ChartPalace', dependent: :destroy

  def Chart.most_empty_houses
    greatest_num = 1
    the_ones_that_did_it = []
    
    all.each do |chart|
      houses = {}; (1..12).each{|t| houses[t]=0}
      
      Star.all.each do |star|
        loc = chart.send "#{star.symbol_name}_id"
        houses[loc] += 1
      end
      empty = 0
      houses.each do |loc, num|
        empty += 1 if num == 0
      end
      
      if empty > greatest_num
        greatest_num = empty
        the_ones_that_did_it = [chart.id]
      elsif empty == greatest_num
        the_ones_that_did_it << chart.id
      end
    end
    
    logger.info "Greatest num: #{greatest_num}"
    logger.info "Who did it? #{the_ones_that_did_it}"
    return nil
  end
  
  def day_of_month=(day)
    if (1..31).include?(day)
      super(day)
    else
      raise "#{day} is not a valid day of month."
    end
  end
  
  def create_chart_palaces
    location = self.ming

    (1..12).each do |i|
      ChartPalace.create(chart: self, palace: Palace.send("_#{i}"), location: location)
      location = location.previous
    end
  end
  
  def name
    hr = hour.branch.ordinal
    solar_date.strftime('%Y-%m-%d-' + (hr < 10 ? "0#{hr}" : hr).to_s)
  end
  
  def self.find_or_create(date)
    if date.hour == 0
      hour = 0
    elsif date.hour == 23
      hour = 23
    elsif date.hour % 2 == 0
      hour = date.hour - 1
    else
      hour = date.hour
    end
    d = DateTime.parse(date.strftime("%Y-%m-%d #{hour}:00"))
    chart = Chart.where(solar_date: d).first
    if chart
      chart
    else
      chart = build(d)
      chart.save!
      chart.create_chart_palaces
      chart
    end
  end
  
  def self.build(date)
    lunar_date = LunarDate.from_date_time(date)
    
    chart = Chart.create solar_date: date, 
              year: lunar_date.year_pillar,
              month: lunar_date.month_pillar, 
              day: lunar_date.day_pillar,
              hour: lunar_date.hour_pillar,
              lunar_year: lunar_date.lunar_year,
              lunar_month: [0, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10][lunar_date.month_pillar.branch.ordinal],
              leap: lunar_date.leap_month,
              day_of_month: lunar_date.day_of_month
    
    chart.attributes = ChartBuilder.new(chart).attributes
    chart
  end
      
  def pillar(name)
    send name
  end
  
  def elemental_scores
    {
      'wood' => wood_score,
      'fire' => fire_score,
      'earth' => earth_score,
      'metal' => metal_score,
      'water' => water_score
    }
  end
  
  def ming; Branch.send("_#{ming_id}") end;def ming=(branch); self.ming_id=branch.ordinal; end;def zi_wei; Branch.send("_#{zi_wei_id}") end;def zi_wei=(branch); self.zi_wei_id=branch.ordinal; end;;def tian_fu; Branch.send("_#{tian_fu_id}") end;def tian_fu=(branch); self.tian_fu_id=branch.ordinal; end;def tian_xiang; Branch.send("_#{tian_xiang_id}") end;def tian_xiang=(branch); self.tian_xiang_id=branch.ordinal; end;def tian_ji; Branch.send("_#{tian_ji_id}") end;def tian_ji=(branch); self.tian_ji_id=branch.ordinal; end;def tai_yang; Branch.send("_#{tai_yang_id}") end;def tai_yang=(branch); self.tai_yang_id=branch.ordinal; end;def wu_qu; Branch.send("_#{wu_qu_id}") end;def wu_qu=(branch); self.wu_qu_id=branch.ordinal; end;def tai_yin; Branch.send("_#{tai_yin_id}") end;def tai_yin=(branch); self.tai_yin_id=branch.ordinal; end;def ju_men; Branch.send("_#{ju_men_id}") end;def ju_men=(branch); self.ju_men_id=branch.ordinal; end;def tian_tong; Branch.send("_#{tian_tong_id}") end;def tian_tong=(branch); self.tian_tong_id=branch.ordinal; end;def tian_liang; Branch.send("_#{tian_liang_id}") end;def tian_liang=(branch); self.tian_liang_id=branch.ordinal; end;def wen_chang; Branch.send("_#{wen_chang_id}") end;def wen_chang=(branch); self.wen_chang_id=branch.ordinal; end;def wen_qu; Branch.send("_#{wen_qu_id}") end;def wen_qu=(branch); self.wen_qu_id=branch.ordinal; end;def lian_zhen; Branch.send("_#{lian_zhen_id}") end;def lian_zhen=(branch); self.lian_zhen_id=branch.ordinal; end;def tan_lang; Branch.send("_#{tan_lang_id}") end;def tan_lang=(branch); self.tan_lang_id=branch.ordinal; end;def qi_sha; Branch.send("_#{qi_sha_id}") end;def qi_sha=(branch); self.qi_sha_id=branch.ordinal; end;def po_jun; Branch.send("_#{po_jun_id}") end;def po_jun=(branch); self.po_jun_id=branch.ordinal; end;def huo_xing; Branch.send("_#{huo_xing_id}") end;def huo_xing=(branch); self.huo_xing_id=branch.ordinal; end;def ling_xing; Branch.send("_#{ling_xing_id}") end;def ling_xing=(branch); self.ling_xing_id=branch.ordinal; end;def yang_ren; Branch.send("_#{yang_ren_id}") end;def yang_ren=(branch); self.yang_ren_id=branch.ordinal; end;def tuo_luo; Branch.send("_#{tuo_luo_id}") end;def tuo_luo=(branch); self.tuo_luo_id=branch.ordinal; end;def you_bi; Branch.send("_#{you_bi_id}") end;def you_bi=(branch); self.you_bi_id=branch.ordinal; end;def zuo_fu; Branch.send("_#{zuo_fu_id}") end;def zuo_fu=(branch); self.zuo_fu_id=branch.ordinal; end;def tian_cun; Branch.send("_#{tian_cun_id}") end;def tian_cun=(branch); self.tian_cun_id=branch.ordinal; end;def tian_yao; Branch.send("_#{tian_yao_id}") end;def tian_yao=(branch); self.tian_yao_id=branch.ordinal; end;def tian_kui; Branch.send("_#{tian_kui_id}") end;def tian_kui=(branch); self.tian_kui_id=branch.ordinal; end;def tian_xi; Branch.send("_#{tian_xi_id}") end;def tian_xi=(branch); self.tian_xi_id=branch.ordinal; end;def di_gong; Branch.send("_#{di_gong_id}") end;def di_gong=(branch); self.di_gong_id=branch.ordinal; end;def tian_yue; Branch.send("_#{tian_yue_id}") end;def tian_yue=(branch); self.tian_yue_id=branch.ordinal; end;def tian_xing; Branch.send("_#{tian_xing_id}") end;def tian_xing=(branch); self.tian_xing_id=branch.ordinal; end;def di_jie; Branch.send("_#{di_jie_id}") end;def di_jie=(branch); self.di_jie_id=branch.ordinal; end;def yi_ma; Branch.send("_#{yi_ma_id}") end;def yi_ma=(branch); self.yi_ma_id=branch.ordinal; end
end

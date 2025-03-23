module FontStylePatch
  RESET_COLOR = "\e[0m" #重置所有颜色和样式
  COLORS = {
    black: "\e[30m", #黑色文本
    red: "\e[31m", #红色文本
    green: "\e[32m", #绿色文本
    yellow: "\e[33m", #黄色文本
    blue: "\e[34m", #蓝色文本
    carmine: "\e[35m", #洋红色文本
    cyan: "\e[36m", #青色文本
    white: "\e[37m" #白色文本
  }
  COLORS.keys.each do |color_name|
    define_method(color_name) do
      return "#{COLORS[color_name]}#{self}#{RESET_COLOR}"
    end
  end
end

module StringPatch
  def nature_case
    self.gsub(/(.)([A-Z])/, '\1 \2').downcase.capitalize
  end
end

class String
  include FontStylePatch
  include StringPatch
end

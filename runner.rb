require_relative "patch"

class RunnerError < StandardError
end


class Task
  @@id = 0
  attr_accessor :task_id, :task_desc, :task_block
  def initialize(task_desc, task_block)
    @@id = @@id + 1
    @task_id = @@id
    @task_desc = task_desc
    @task_block = task_block
  end
end

class Runner
  def initialize(&block)
    @current_task = nil
    @tasks = []
    init_platform
    instance_eval(&block)
    self
  end

  def init_platform
    @macos_arch, _ = RUBY_PLATFORM.split("-") # x86_64, ?
    @macos_arch_prefix = nil
    @macos_target_verison = nil

    case @macos_arch
    when /x86_64/i
      @macos_arch_prefix = "x64"
      @macos_target_verison = "10.9"
    when /arm_64/i
      @macos_arch_prefix = "arm64"
      @macos_target_verison = "11.0"
    else
      raise RunnerError, "MacOS - #{@macos_arch} arch not support!"
    end
  end

  def task(task_desc, &block)
    @tasks << Task.new(task_desc, block)
  end

  def sh(command_text)
    result = system(command_text)
    if result
      on_success(command_text)
    else
      on_fail(command_text)
      raise RunnerError
    end
  end

  def on_success(command_text = nil)
    puts "[success] task@#{@current_task.task_id} shell: #{command_text}".green
  end

  def on_fail(command_text = nil)
    puts "[fail] task@#{@current_task.task_id} shell: #{command_text}".yellow
  end

  def run
    @tasks.each do |task|
      @current_task = task
      blk = @current_task.task_block
      puts "#{"-"* 20}".green
      puts "[start task@#{@current_task.task_id}] #{@current_task.task_desc}".green
      instance_eval(&blk)
      puts "[finished task@#{@current_task.task_id}]".green
      @current_task = nil
    end
  end
end

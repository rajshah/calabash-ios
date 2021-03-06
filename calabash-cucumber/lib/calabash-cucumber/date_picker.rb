require 'date'

module Calabash
  module Cucumber
    module DatePicker
      include Calabash::Cucumber::Core

      # equivalent formats for ruby and objc
      # we convert DateTime object to a string
      # and pass the format that objc can use
      # to convert the string into NSDate
      RUBY_DATE_AND_TIME_FMT = '%Y_%m_%d_%H_%M'
      OBJC_DATE_AND_TIME_FMT = 'yyyy_MM_dd_HH_mm'

      # picker modes
      UI_DATE_PICKER_MODE_TIME = 0
      UI_DATE_PICKER_MODE_DATE = 1
      UI_DATE_PICKER_MODE_DATE_AND_TIME = 2
      UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER = 3

      def date_picker_mode(picker_id=nil)
        query_str = should_see_date_picker picker_id
        res = query(query_str, :datePickerMode)
        if res.empty?
          screenshot_and_raise "should be able to get mode from picker with query '#{query_str}'"
        end
        res.first
      end

      def time_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_TIME
      end

      def date_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_DATE
      end

      def date_and_time_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_DATE_AND_TIME
      end

      def countdown_mode?(picker_id=nil)
        date_picker_mode(picker_id) == UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER
      end

      # ensuring picker is visible

      def query_string_for_picker (picker_id = nil)
        picker_id.nil? ? 'datePicker' : "datePicker marked:'#{picker_id}'"
      end

      def should_see_date_picker (picker_id=nil)
        query_str = query_string_for_picker picker_id
        if query(query_str).empty?
          screenshot_and_raise "should see picker with query '#{query_str}'"
        end
        query_str
      end


      # minimum and maximum dates
      # appledoc ==> The property is an NSDate object or nil (the default),
      # which means no maximum date.
      def maximum_date_time_from_picker (picker_id = nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end

        query_str = should_see_date_picker picker_id
        res = query(query_str, :maximumDate)
        if res.empty?
          screenshot_and_raise "should be able to get max date from picker with query '#{query_str}'"
        end
        return nil if res.first.nil?
        DateTime.parse(res.first)
      end

      # appledoc ==> The property is an NSDate object or nil (the default),
      # which means no minimum date.
      def minimum_date_time_from_picker (picker_id = nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end

        query_str = should_see_date_picker picker_id
        res = query(query_str, :minimumDate)
        if res.empty?
          screenshot_and_raise "should be able to get min date from picker with query '#{query_str}'"
        end
        return nil if res.first.nil?
        DateTime.parse(res.first)
      end

      # date time from picker
      def date_time_from_picker (picker_id=nil)
        if countdown_mode? picker_id
          screenshot_and_raise 'method is not available for pickers that are not in date or date time mode'
        end
        query_str = query_string_for_picker picker_id
        res = query(query_str, :date)
        if res.empty?
          screenshot_and_raise "should be able to get date from picker with query '#{query_str}'"
        end
        DateTime.parse(res.first)
      end


      # changing picker date time
      def args_for_change_date_on_picker(options)
        args = []
        if options.has_key?(:notify_targets)
          args << options[:notify_targets] ? 1 : 0
        else
          args << 1
        end

        if options.has_key?(:animate)
          args << options[:animate] ? 1 : 0
        else
          args << 1
        end
        args
      end


      # sets the date and time on picker identified by <tt>options[:picker_id]</tt>
      # using the DateTime +target_dt+
      #
      # valid options are:
      #
      #        :animate - animate the change - default is +true+
      #      :picker_id - the id (or mark) of the date picker - default is +nil+ which
      #                   will target the first visible date picker
      # :notify_targets - notify all objc targets that the date picker has changed
      #                   default is +true+
      #
      # when <tt>:notify_targets = true</tt> this operation iterates through the
      # target/action pairs on the objc +UIDatePicker+ instance and calls
      # <tt>performSelector:<action> object:<target></tt> to simulate a +UIEvent+
      #
      # raises an error if
      # * no UIDatePicker can be found
      # * the target date is greater than the picker's maximum date
      # * the target date is less than the picker's minimum date
      # * the target date is not a DateTime object
      def picker_set_date_time (target_dt, options = {:animate => true,
                                                      :picker_id => nil,
                                                      :notify_targets => true})
        unless target_dt.is_a?(DateTime)
          raise "target_dt must be a DateTime but found '#{target_dt.class}'"
        end

        picker_id = options == nil ? nil : options[:picker_id]

        if time_mode?(picker_id) == UI_DATE_PICKER_MODE_COUNT_DOWN_TIMER
          pending('picker is in count down mode which is not yet supported')
        end

        target_str = target_dt.strftime(RUBY_DATE_AND_TIME_FMT).squeeze(' ').strip
        fmt_str = OBJC_DATE_AND_TIME_FMT

        args = args_for_change_date_on_picker options
        query_str = query_string_for_picker picker_id

        views_touched = map(query_str, :changeDatePickerDate, target_str, fmt_str, *args)
        msg = "could not change date on picker to '#{target_dt}' using query '#{query_str}' with options '#{options}'"
        assert_map_results(views_touched,msg)
        views_touched
      end
    end
  end
end

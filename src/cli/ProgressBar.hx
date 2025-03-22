package cli;

class ProgressBar
{
    var msg: String;
    final length: Int;

    public function new(msg: String, length: Int = 50)
    {
        this.msg = msg;
        this.length = length;

        print(0.0);
    }

    public function print(percent: Float, ?msg: String)
    {
        if (msg != null)
        {
            this.msg = msg;
        }

        Sys.print('\r');
        Sys.print('[');

        for (i in 0...length)
        {
            if ((i / length) < percent)
            {
                if ((i + 1) / length >= percent && percent < 1.0)
                {
                    Sys.print('>');
                }
                else
                {
                    Sys.print('=');
                }
            }
            else
            {
                Sys.print(' ');
            }
        }

        Sys.print('] ');
        Sys.print(this.msg);
    }

    public function done()
    {
        Sys.print('\r');
        final lineLength: Int = length + 3 + msg.length;
        for (_ in 0...lineLength)
        {
            Sys.print(' ');
        }
        Sys.print('\r');
    }
}

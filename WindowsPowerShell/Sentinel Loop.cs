using System;

class Kodify_Example
{
    static void Main()
    {
        string userInput = "";
        int runningSum = 0;
        int count = 0;

        while (true)
        {
            Console.Write("Enter a number (<Enter> to quit): ");
            userInput = Console.ReadLine();

            if (userInput == "")
            {
                break;
            }

            runningSum += Convert.ToInt32(userInput);
            count++;
        }

        Console.WriteLine($"Average of {count} numbers = {runningSum / (double)count}");
    }
}
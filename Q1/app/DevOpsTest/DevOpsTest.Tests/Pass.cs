using NUnit.Framework;
using DevOpsTest;

namespace DevOpsTest.Tests
{
    public class Tests
    {
        [SetUp]
        public void Setup()
        {
        }

        [Test]
        public void Pass()
        {
            Assert.Pass();
        }
    }
}
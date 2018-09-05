# Get some files
cwd = os.getcwd()
# make a string to select our spikes files
spike_str = "{}{}*spikes.csv".format(cwd, os.sep)
print("Spike string: " +spike_str)

fns = glob(spike_str)
pprint(fns)

def as_spikenum(filename):
    split = filename.split("_")
    numbers = [s for s in split if s.isdigit()]
    if len(numbers)==1:
        return numbers[0]
    else:
        print("Found more than one number, giving you the last?")
        return numbers[-1]


df = pd.read_csv(fns[0]) # read the first (zero-indexed) file
df['cell'] = as_spikenum(fns[0])

# if we have more, read them too, assuming they're of the same format
if len(fns)>1:
    for fn in fns:
        adf = pd.read_csv(fn)
        adf['cell'] = as_spikenum(fn)

        # concatenate, ignoring a row index which doesn't help us much.
        df = pd.concat([df,adf],
                       ignore_index=True)

df.shape

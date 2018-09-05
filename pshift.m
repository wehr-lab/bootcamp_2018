function [s, fs] = pshift(ap, r, play, save)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pitch shift sound at path ap with sampling rate fs by ratio r
% play arg t/f is whether to play stretched audio at end 
% Uses Phase Vocoder Instructions from http://www.mathworks.com/help/dsp/examples/pitch-shifting-and-time-dilation-using-a-phase-vocoder.html
% 1.0 - JLS 2.20.16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Init system objects
%set analysis hop size/synthesis hop size to ratio of transformation
%try 10x for ~1kHz
wlen = 4096;
alen = 256;
slen = 256*r;
hratio = slen/alen;
%lendn = lendn/alen;

%source, buffer, window, fft, ifft, player, logger objects
a = dsp.AudioFileReader(ap,'SamplesPerFrame', alen, 'OutputDataType','double');
fs = a.SampleRate;
b = dsp.Buffer(wlen, wlen - alen);
w = dsp.Window('Hanning','Sampling','Periodic');
f = dsp.FFT;
i = dsp.IFFT('ConjugateSymmetricInput', true, 'Normalize', false);
p = dsp.AudioPlayer('SampleRate',fs);
l = dsp.SignalSink;

%loop variables
yprevw = zeros(wlen-slen,1);
g = 1/(wlen*sum(hanning(wlen,'periodic').^2)/slen);
unwrap = 2*pi*alen*(0:wlen-1)'/wlen;
yangle = zeros(wlen,1);
first = true;

%%%%%%%%%%%%%%%%%%
%Loop
snum = 0;
while ~isDone(a)
    y = step(a);

    %step(p, y);    % Play back original audio

    % ST-FFT
    % FFT of a windowed buffered signal
    yfft = step(f, step(w, step(b, y)));

    % Convert complex FFT data to magnitude and phase.
    ymag       = abs(yfft);
    yprevangle = yangle;
    yangle     = angle(yfft);

    % Synthesis Phase Calculation
    % The synthesis phase is calculated by computing the phase increments
    % between successive frequency transforms, unwrapping them, and scaling
    % them by the ratio between the analysis and synthesis hop sizes.
    yunwrap = (yangle - yprevangle) - unwrap;
    yunwrap = yunwrap - round(yunwrap/(2*pi))*2*pi;
    yunwrap = (yunwrap + unwrap) * hratio;
    if first
        ysangle = yangle;
        first = false;
    else
        ysangle = ysangle + yunwrap;
    end

    % Convert magnitude and phase to complex numbers.
    ys = ymag .* complex(cos(ysangle), sin(ysangle));
    
    %If the signal is zero for awhile (eg. from denoising) it will end up
    %as a real value which the step is NOT down with -JLS030416
    if isreal(ys)
        ys = complex(ys);
    end

    % IST-FFT
    ywin  = step(w, step(i,ys));    % Windowed IFFT

    % Overlap-add operation
    olapadd  = [ywin(1:end-slen,:) + yprevw; 
        ywin(end-slen+1:end,:)];
    yistfft  = olapadd(1:slen,:);
    yprevw = olapadd(slen+1:end,:);

    % Compensate for the scaling that was introduced by the overlap-add
    % operation
    yistfft = yistfft * g;

    step(l, yistfft);     % Log signal
end

release(a);
%decimate to get back to original fs
atfm = l.Buffer(:)';
adec = decimate(atfm,hratio);
s = adec;

%s = l.Buffer(:)';

if play
    loggedSpeech = l.Buffer(200:end)';
    player = dsp.AudioPlayer('SampleRate', fs);
    % Play time-stretched signal
    disp('Playing pshift signal...');
    step(player,loggedSpeech.');
else
    disp('Not playing pshift signal');
end

if save
    [path, fn, ext] = fileparts(ap);
    fn = [fn,'_pshift'];
    save_fn = [path,filesep, fn, ext];
    fprintf('Saving to %s',save_fn)
    audiowrite(save_fn,s,fs,'BitsPerSample',24);
end
    